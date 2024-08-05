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
    private let baseUrl = "http://127.0.0.1:8080" //https://dynamicisland-4bizugbf.b4a.run"
    private var currentActivity: Activity<BitcoinTickerAttributes>? = nil
    private var lastPrice: Double = 0.0
    private var price: Double = 0.0
    @Published var coinList = [Crypto]()
    @Published var originalList = [Crypto]()
    @Published var message: String?
    var timer: Timer?
    override init() {
        super.init()
    }
    
    func saveActivity(code: String?) {
        UserDefaults.standard.setValue(code ?? "", forKey: "ticker")
    }
    
    func getSavedActivity() -> String {
        return UserDefaults.standard.string(forKey: "ticker") ?? ""
    }
    
    func callAPIToUpdate(deviceToken: String, code: String) {
        let baseURL = "\(baseUrl)/dynamic-island/subscribe"
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "DeviceID"
        let crypto = self.coinList.first {
            $0.code == code
        }
        var urlComponents = URLComponents(string: baseURL)!
        var queryItems = [
            URLQueryItem(name: "deviceToken", value: deviceToken),
            URLQueryItem(name: "symbol", value: code),
            URLQueryItem(name: "deviceId", value: deviceId),
            URLQueryItem(name: "type", value: "crypto"),
            URLQueryItem(name: "image", value: crypto?.image ?? "")
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
    
    func setStopTime(time: Date) {
        let url = "\(baseUrl)/dynamic-island/set-stop"
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "DeviceID"
        var urlComponents = URLComponents(string: url)!
        urlComponents.queryItems = [
            URLQueryItem(name: "deviceId", value: deviceId),
            URLQueryItem(name: "stop", value: "\(Date().timeIntervalSince1970)")
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
    
    func startActivity(code: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("You can't start live activity.")
            return
        }
        LiveActivityManager.shared.endActivity(completion: { [weak self] in
            guard let self else { return }
            let atttribute = BitcoinTickerAttributes(name:"push")
            let initialState = BitcoinTickerAttributes.ContentState(image: self.originalList.first(where: { $0.code == code})?.image ?? "", price: "", symbol: self.originalList.first(where: { $0.code == code})?.code ?? "", isIncrease: true)
            self.currentActivity = try! Activity<BitcoinTickerAttributes>.request(
                attributes: atttribute,
                content: .init(state:initialState , staleDate: nil),
                pushType: .token
            )
            self.saveActivity(code: code)
            DispatchQueue.main.async {
                withAnimation {
                    self.message = "Starting..."
                }
            }
            Task {
                for await pushToken in self.currentActivity!.pushTokenUpdates {
                    let pushTokenString = pushToken.reduce("") {
                        $0 + String(format: "%02x", $1)
                    }
                    print("Activity:\(self.currentActivity?.id ?? "") push token: \(pushTokenString)")
                    self.callAPIToUpdate(deviceToken: pushTokenString, code: code)
                }
            }
        })

        self.startTimer(code: code)
    }
    
    private func startTimer(code: String) {
        self.timer?.invalidate()
        self.timer = nil
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            print("timer running")
            self.fetchPrice(code: code)
        }
    }
    
    private func fetchPrice(code: String) {
        self.lastPrice = self.price
        self.getPrice(code: code) { price in
            self.price = Double(price) ?? 0
            self.updateActivity(type: self.originalList.first(where: { $0.code == code}) ?? .empty, price: price, isIncrease: self.price >= self.lastPrice)
        }
    }

    func updateActivity(type: Crypto, price: String, isIncrease: Bool) {
        var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = UIBackgroundTaskIdentifier.invalid
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            Task {
                for activity in Activity<BitcoinTickerAttributes>.activities {
                    let contentState: BitcoinTickerAttributes.ContentState = BitcoinTickerAttributes.ContentState(
                        image: type.image,
                        price: price,
                        symbol: type.code,
                        isIncrease: isIncrease
                    )
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
            self.saveActivity(code: nil)
            self.callAPIToStop(completion: completion)
        }
    }
}


extension LiveActivityManager {
    func getCoinList() {
        Task { @MainActor in
            self.message = "Loading..."
            self.originalList = await self.getCoingeckoCryptoList()
            self.coinList = self.originalList
            self.message = nil
        }
    }
    func getCoingeckoCryptoList() async -> [Crypto] {
        return await withCheckedContinuation { con in
            let url = URL(string: "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd")!
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    print("Invalid response or status code")
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    return
                }
                do {
                    let object = try JSONDecoder().decode([CoinGecko].self, from: data)
                    con.resume(returning: object.map({
                        $0.toCrypto()
                    }))
                } catch let jsonError {
                    print("JSON error: \(jsonError)")
                    con.resume(returning: [])
                }
            }
            task.resume()
        }
    }
    
    func getCoinbaseCryptoList() async -> [CoinBaseCryptoType] {
        return await withCheckedContinuation { con in
            let url = URL(string: "https://api.coinbase.com/v2/currencies/crypto")!
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    print("Invalid response or status code")
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    return
                }
                do {
                    let object = try JSONDecoder().decode(CoinBaseCryptoListResponse.self, from: data)
                    con.resume(returning: object.data)
                } catch let jsonError {
                    print("JSON error: \(jsonError)")
                    con.resume(returning: [])
                }
            }
            task.resume()
        }
    }
    func getPrice(code: String, completion: @escaping (String) -> Void) {
        let url = URL(string: "https://api.coinbase.com/v2/prices/\(code)-USD/spot")!
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Invalid response or status code")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            do {
                let object = try JSONDecoder().decode(CoinBaseCrypto.self, from: data)
                completion(object.data.amount)
            } catch let jsonError {
                print("JSON error: \(jsonError)")
            }
        }.resume()
    }
}
