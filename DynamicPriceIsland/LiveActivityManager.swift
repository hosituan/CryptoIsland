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


class LiveActivityManager: NSObject, ObservableObject {
    public static let shared: LiveActivityManager = LiveActivityManager()
    private let baseUrl = "https://dynamicisland-4bizugbf.b4a.run"
    private var currentActivity: Activity<BitcoinTickerAttributes>? = nil
    private var lastPrice: Double = 0.0
    private var price: Double = 0.0
    @Published var isShowAlert = false
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
        urlComponents.queryItems = [
            URLQueryItem(name: "deviceToken", value: deviceToken),
            URLQueryItem(name: "symbol", value: type.rawValue),
            URLQueryItem(name: "deviceId", value: deviceId),
            URLQueryItem(name: "type", value: "crypto"),
        ]
        guard let url = urlComponents.url else {
            fatalError("Invalid URL")
        }
        let session = URLSession.shared
        DispatchQueue.main.async {
            self.isShowAlert = true
        }
        let task = session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isShowAlert = false
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
    
    func callAPIToStop() {
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
                self.isShowAlert = false
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
        LiveActivityManager.shared.endActivity()
        self.isShowAlert = true
        do {
            
            let atttribute = BitcoinTickerAttributes(name:"push")
            let initialState = BitcoinTickerAttributes.ContentState(price: "", symbol: "", isIncrease: true)
            let activity = try Activity<BitcoinTickerAttributes>.request(
                attributes: atttribute,
                content: .init(state:initialState , staleDate: nil),
                pushType: .token
            )
            self.currentActivity = activity
            self.saveActivity(type: type)
            Task {
                for await activityData in Activity<BitcoinTickerAttributes>.activityUpdates {
                    for await pushToken in activityData.pushTokenUpdates {
                        let pushTokenString = pushToken.reduce("") {
                            $0 + String(format: "%02x", $1)
                        }
                        print("Activity:\(activity.id) push token: \(pushTokenString)")
                        self.callAPIToUpdate(deviceToken: pushTokenString, type: type)
                    }
                }
            }
            self.startTimer(type: type)
        } catch {
            self.isShowAlert = false
            print("start Activity From App:\(error)")
        }
    }
    
    private func startTimer(type: PriceTicker) {
        self.timer?.invalidate()
        self.timer = nil
        self.timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            self.fetchPrice(type: type)
        }
    }
    
    private func fetchPrice(type: PriceTicker) {
        type.getPrice(source: .coinbase) { tickerPrice in
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
                    await activity.update(ActivityContent(state: contentState, staleDate: Date.now + 15, relevanceScore: 50), alertConfiguration: nil)
                }
            }
        }
    }
    
    func endActivity() {
        self.timer?.invalidate()
        self.timer = nil
        Task.detached(priority: .high) {
            for activity in Activity<BitcoinTickerAttributes>.activities {
                print("Ending Live Activity: \(activity.id)")
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            self.callAPIToStop()
            self.saveActivity(type: nil)
        }
    }
    
}
