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
import Combine


class LiveActivityManager: NSObject, ObservableObject {
    public static let shared: LiveActivityManager = LiveActivityManager()
    private let baseUrl = "https://dynamicisland-4bizugbf.b4a.run"
    private var currentActivity: Activity<TickerAttribute>? = nil
    private var lastPrice: Double = 0.0
    private var price: Double = 0.0
    @Published var favorites = [MoneyAsset]()
    @Published var recommendedList = [MoneyAsset]()
    @Published var searchResultList = [MoneyAsset]()
    @Published var message: String?
    @Published var selectedSheetAsset: MoneyAsset?
    @Published var searchText: String = ""
    var cancelables = Set<AnyCancellable>()
    var timer: Timer?
    override init() {
        super.init()
        $searchText.debounce(for: 0.3, scheduler: RunLoop.main).sink { value in
            self.search(text: value.trimmingCharacters(in: .whitespaces))
        }.store(in: &cancelables)
    }
    
    func saveActivity(code: String?) {
        UserDefaults.standard.setValue(code ?? "", forKey: "ticker")
    }
    
    func getSavedActivity() -> String {
        return UserDefaults.standard.string(forKey: "ticker") ?? ""
    }
    
    func callAPIToUpdate(deviceToken: String, asset: MoneyAsset) {
        let baseURL = "\(baseUrl)/dynamic-island/subscribe"
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "DeviceID"
        
        var urlComponents = URLComponents(string: baseURL)!
        let nextMins = Configuration.stopAfter * 60
        let stopAt = Int(Date().addingMinutes(Int(nextMins)).timeIntervalSince1970)
        Configuration.stopAt = stopAt
        var queryItems = [
            URLQueryItem(name: "deviceToken", value: deviceToken),
            URLQueryItem(name: "symbol", value: asset.symbol),
            URLQueryItem(name: "deviceId", value: deviceId),
            URLQueryItem(name: "screener", value: asset.screener),
            URLQueryItem(name: "exchange", value: asset.exchange),
            URLQueryItem(name: "type", value: "crypto"),
            URLQueryItem(name: "image", value: asset.image ?? ""),
            URLQueryItem(name: "stop", value: "\(stopAt)")
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
            URLQueryItem(name: "stop", value: "\(Int(Date().timeIntervalSince1970))")
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
    
    func startActivity(asset: MoneyAsset) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("You can't start live activity.")
            return
        }
        LiveActivityManager.shared.endActivity(completion: { [weak self] in
            guard let self else { return }
            let atttribute = TickerAttribute(name:"push")
            let initialState = TickerAttribute.ContentState(image: asset.image ?? "", price: "", symbol: asset.symbol, isIncrease: true)
            self.currentActivity = try! Activity<TickerAttribute>.request(
                attributes: atttribute,
                content: .init(state:initialState , staleDate: nil),
                pushType: .token
            )
            self.saveActivity(code: asset.symbol)
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
                    self.callAPIToUpdate(deviceToken: pushTokenString, asset: asset)
                }
            }
        })

//        self.startTimer(code: code)
    }
    
    private func startTimer(code: String) {
        self.timer?.invalidate()
        self.timer = nil
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            print("timer running")
            if Configuration.stopAt > Int(Date().timeIntervalSince1970) {
                self.fetchPrice(code: code)
            } else {
                self.timer?.invalidate()
            }
        }
    }
    
    private func fetchPrice(code: String) {
//        self.lastPrice = self.price
//        self.getPrice(code: code) { price in
//            self.price = Double(price) ?? 0
//            self.updateActivity(type: self.originalList.first(where: { $0.code == code}) ?? .empty, price: price, isIncrease: self.price >= self.lastPrice)
//        }
    }

    func updateActivity(type: MoneyAsset, price: String, isIncrease: Bool) {
        var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = UIBackgroundTaskIdentifier.invalid
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            Task {
                for activity in Activity<TickerAttribute>.activities {
                    let contentState: TickerAttribute.ContentState = TickerAttribute.ContentState(
                        image: type.image ?? "",
                        price: price,
                        symbol: type.symbol,
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
            for activity in Activity<TickerAttribute>.activities {
                print("Ending Live Activity: \(activity.id)")
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            self.saveActivity(code: nil)
            self.callAPIToStop(completion: completion)
        }
    }
}

extension LiveActivityManager {
    func loadData() {
        self.favorites = getFavoriteList()
        Task { @MainActor in
//            self.recommendedList = await getRecommendedList().map {
//                MoneyAsset(code: $0.symbol, screener: "", exchange: "", open: 0, close: 0, image: $0.logoid ?? "", name: "")
//            }
            
        }
    }
    
    func search(text: String) {
        guard text != "" else {
            DispatchQueue.main.async { self.searchResultList = [] }
            return
        }
        guard let url = URL(string: "\(baseUrl)/trading-view/search?query=\(text)") else {
            DispatchQueue.main.async { self.searchResultList = [] }
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                DispatchQueue.main.async { self.searchResultList = [] }
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
                DispatchQueue.main.async { self.searchResultList = [] }
                return
            }
            do {
                let object = try JSONDecoder().decode([MoneyAsset].self, from: data)
                DispatchQueue.main.async { self.searchResultList = object }
            } catch let jsonError {
                print("JSON error: \(jsonError)")
                DispatchQueue.main.async { self.searchResultList = [] }
            }
        }.resume()
    }
    
    func getFavoriteList() -> [MoneyAsset] {
        let favoriteAssets = Configuration.favoriteAssets
        return favoriteAssets.compactMap { asset in
            let data = asset.components(separatedBy: "+")
            guard data.count == 5 else { return nil }
            return MoneyAsset(symbol: data[0], screener: data[1], exchange: data[2], open: 0, close: 0, image: data[4], desc: data[3])
        }
    }
    
    func addFavoriteAsset(asset: MoneyAsset) {
        var currentFavorite = Configuration.favoriteAssets
        let assetString = "\(asset.symbol)+\(asset.screener)+\(asset.exchange)+\(asset.desc ?? "")+\(asset.image ?? "")"
        if !currentFavorite.contains(assetString) {
            currentFavorite.append(assetString)
            Configuration.favoriteAssets = currentFavorite
        }
    }
    
    func removeFavoriateAsset(asset: MoneyAsset) {
        var currentFavorite = Configuration.favoriteAssets
        let assetString = "\(asset.symbol)+\(asset.screener)+\(asset.exchange)+\(asset.desc ?? "")+\(asset.image ?? "")"
        currentFavorite.removeAll {
            $0 == assetString
        }
        Configuration.favoriteAssets = currentFavorite
    }
    
    func getRecommendedList() async -> [TradingViewSymbol] {
        guard let url = URL(string: "\(baseUrl)/trading-view/recommended") else { return [] }
        return await withCheckedContinuation { con in
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    con.resume(returning: [])
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
                    con.resume(returning: [])
                    return
                }
                do {
                    let object = try JSONDecoder().decode(RecommenedListResponse.self, from: data)
                    let result = object.items.map {
                        $0.relatedSymbols
                    }
                    var res = [TradingViewSymbol]()
                    result.forEach { list in
                        res.append(contentsOf: list)
                    }
                    con.resume(returning: res)
                } catch let jsonError {
                    print("JSON error: \(jsonError)")
                    con.resume(returning: [])
                }
            }.resume()
        }
    }
    func loadData(asset: MoneyAsset) async -> MoneyAsset {
        var urlComponents = URLComponents(string: "\(baseUrl)/trading-view/data")!
        urlComponents.queryItems = [
            URLQueryItem(name: "symbol", value: asset.symbol),
            URLQueryItem(name: "screener", value: asset.screener),
            URLQueryItem(name: "exchange", value: asset.exchange),
        ]
        guard let url = urlComponents.url else { return asset }
        return await withCheckedContinuation { con in
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    con.resume(returning: asset)
                    return
                }
                guard let data = data else {
                    con.resume(returning: asset)
                    return
                }
                do {
                    let object = try JSONDecoder().decode(MoneyAssetResponse.self, from: data)
                    con.resume(returning: object.data)
                } catch let jsonError {
                    print("JSON error: \(jsonError)")
                    con.resume(returning: asset)
                }
            }.resume()
        }
    }
    
}

struct RecommenedListResponse: Codable {
    let items: [TradingViewItem]
}

struct TradingViewItem: Codable {
    let relatedSymbols: [TradingViewSymbol]
}

struct TradingViewSymbol: Codable {
    let logoid: String?
    let symbol: String
}
