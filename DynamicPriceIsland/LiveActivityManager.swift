//
//  LiveActivityManager.swift
//  DynamicPriceIsland
//
//  Created by Ho Si Tuan on 25/07/2024.
//

import Foundation
import ActivityKit
import os.log
import UIKit
import SwiftUI


class LiveActivityManager: NSObject, ObservableObject {
    public static let shared: LiveActivityManager = LiveActivityManager()
    private let baseUrl = "https://dynamicisland-4bizugbf.b4a.run"
    private var currentActivity: Activity<BitcoinTickerAttributes>? = nil
    private var lastPrice: Double = 0.0
    private var price: Double = 0.0
    @Published var message: String?
    var timer: Timer?
    override init() {
        super.init()
    }
    
    func saveActivity(type: PriceTicker?) {
        UserDefaults.standard.setValue(type?.rawValue ?? "", forKey: "ticker")
    }
    
    func getSavedActivity() -> PriceTicker? {
        return PriceTicker(rawValue: UserDefaults.standard.string(forKey: "ticker") ?? "")
    }
    
    func callAPIToUpdate(deviceToken: String, type: PriceTicker) {
        let baseURL = "\(baseUrl)/dynamic-island/subscribe"
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "DeviceID"
        var urlComponents = URLComponents(string: baseURL)!
        var queryItems = [
            URLQueryItem(name: "deviceToken", value: deviceToken),
            URLQueryItem(name: "symbol", value: type.rawValue),
            URLQueryItem(name: "deviceId", value: deviceId),
            URLQueryItem(name: "type", value: "crypto")
        ]
        #if DEBUG
        queryItems.append(URLQueryItem(name: "env", value: "debug"))
        #else
        queryItems.append(URLQueryItem(name: "env", value: "production"))
        #endif
        urlComponents.queryItems = queryItems
        guard let url = urlComponents.url else {
            fatalError("Invalid URL")
        }
        let session = URLSession.shared
        DispatchQueue.main.async {
            self.message = "Processing..."
        }
        let task = session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.message = nil
            }
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                print("No data received")
                return
            }
            print("Response data: \(String(data: data, encoding: .utf8) ?? "")")
        }
        task.resume()
    }
    
    func callAPIToStop(completion: @escaping (() -> Void)) {
        let baseURL = "\(baseUrl)/dynamic-island/unsubscribe"
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "DeviceID"
        var urlComponents = URLComponents(string: baseURL)!
        urlComponents.queryItems = [
            URLQueryItem(name: "deviceId", value: deviceId)
        ]
        guard let url = urlComponents.url else {
            fatalError("Invalid URL")
        }
        let session = URLSession.shared
        let task = session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.message = nil
            }
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                print("No data received")
                return
            }
            print("Response data: \(String(data: data, encoding: .utf8) ?? "")")
            completion()
        }
        
        task.resume()
    }
    
    func moveToHomeScreen() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.perform(NSSelectorFromString("suspend"))
        }
    }
    
    func startActivity(type: PriceTicker) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("You can't start live activity.")
            return
        }
        LiveActivityManager.shared.endActivity(completion: { [weak self] in
            guard let self else { return }
            let atttribute = BitcoinTickerAttributes(name:"push")
            let initialState = BitcoinTickerAttributes.ContentState(price: "", symbol: "", isIncrease: true)
            self.currentActivity = try! Activity<BitcoinTickerAttributes>.request(
                attributes: atttribute,
                content: .init(state:initialState , staleDate: nil),
                pushType: .token
            )
            self.saveActivity(type: type)
            DispatchQueue.main.async {
                withAnimation {
                    self.message = "Starting..."
                }
            }
            Task.detached(priority: .high) {
                for await pushToken in self.currentActivity!.pushTokenUpdates {
                    let pushTokenString = pushToken.reduce("") {
                        $0 + String(format: "%02x", $1)
                    }
                    print("Activity:\(self.currentActivity?.id ?? "") push token: \(pushTokenString)")
                    self.callAPIToUpdate(deviceToken: pushTokenString, type: type)
                }
            }
        })
        self.fetchPrice(type: type)
        self.startTimer(type: type)
    }
    
    private func startTimer(type: PriceTicker) {
        self.timer?.invalidate()
        self.timer = nil
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            print("timer running")
            self.fetchPrice(type: type)
        }
    }
    
    private func fetchPrice(type: PriceTicker) {
        type.getPrice(source: .coinbase) { [weak self] tickerPrice in
            guard let self else { return }
            self.lastPrice = self.price
            self.price = tickerPrice.toDouble()
            print(self.price)
            self.updateActivity(type: type, price: "\(self.price)", isIncrease: self.price >= self.lastPrice)
        }
    }
    
    func updateActivity(type: PriceTicker, price: String, isIncrease: Bool) {
        var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = UIBackgroundTaskIdentifier.invalid
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            Task {
                for activity in Activity<BitcoinTickerAttributes>.activities {
                    let contentState: BitcoinTickerAttributes.ContentState = BitcoinTickerAttributes.ContentState(price: price, symbol: type.rawValue, isIncrease: isIncrease)
                    await activity.update(ActivityContent(state: contentState, staleDate: Date.now, relevanceScore: 0), alertConfiguration: nil)
                }
            }
        }
    }
    
    func endActivity(completion: @escaping (() -> Void)) {
        self.timer?.invalidate()
        self.timer = nil
        Task.detached(priority: .high) {
            for activity in Activity<BitcoinTickerAttributes>.activities {
                print("Ending Live Activity: \(activity.id)")
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            self.saveActivity(type: nil)
            self.callAPIToStop(completion: completion)
        }
    }
    
}
