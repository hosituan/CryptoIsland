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

enum Screener: String, CaseIterable, Equatable, Identifiable {
    var id: String { self.rawValue }
    case all
    case america
    case forex
    case crypto
    case indonesia
    case india
    case italy
    case cfd
    case uk
    case brazil
    case vietnam
    case rsa
    case ksa
    case australia
    case russia
    case thailand
    case philippines
    case taiwan
    case sweden
    case france
    case turkey
    case euronext
    case germany
    case spain
    case hongkong
    case korea
    case malaysia
    case canada

    var title: String {
        switch self {
        case .all: return "All"
        case .america: return "United States"
        case .forex: return "Forex"
        case .crypto: return "Cryptocurrency"
        case .indonesia: return "Indonesia"
        case .india: return "India"
        case .italy: return "Italy"
        case .cfd: return "CFD"
        case .uk: return "United Kingdom"
        case .brazil: return "Brazil"
        case .vietnam: return "Vietnam"
        case .rsa: return "South Africa"
        case .ksa: return "Saudi Arabia"
        case .australia: return "Australia"
        case .russia: return "Russia"
        case .thailand: return "Thailand"
        case .philippines: return "Philippines"
        case .taiwan: return "Taiwan"
        case .sweden: return "Sweden"
        case .france: return "France"
        case .turkey: return "Turkey"
        case .euronext: return "Euronext"
        case .germany: return "Germany"
        case .spain: return "Spain"
        case .hongkong: return "Hong Kong"
        case .korea: return "South Korea"
        case .malaysia: return "Malaysia"
        case .canada: return "Canada"
        }
    }
}


class LiveActivityManager: NSObject, ObservableObject {
    public static let shared: LiveActivityManager = LiveActivityManager()
//    private let baseUrl = "http://127.0.0.1:8080"
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
    @Published var screener: Screener = .all
    @Published var isSearching = false
    @Published var imageData = [TradingViewSymbol]()
    var cancelables = Set<AnyCancellable>()
    var timer: Timer?
    override init() {
        super.init()
        $searchText.debounce(for: 0.3, scheduler: RunLoop.main).sink { value in
            self.search(text: value.trimmingCharacters(in: .whitespaces), screener: self.screener)
        }.store(in: &cancelables)
        $screener.debounce(for: 0.3, scheduler: RunLoop.main).sink { value in
            self.search(text: self.searchText.trimmingCharacters(in: .whitespacesAndNewlines), screener: value)
        }.store(in: &cancelables)
        self.loadData()
        self.favorites.forEach {
            self.addSymbol(asset: $0)
        }
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
        var nextMins = Configuration.stopAfter * 60
        if nextMins == 0 {
           nextMins = 9999
        }
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
            let initialState = TickerAttribute.ContentState(image: asset.image ?? "", price: "", symbol: asset.symbol ?? "", isIncrease: true)
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

//        self.startTimer(asset: asset)
    }
    
    private func startTimer(asset: MoneyAsset) {
        self.timer?.invalidate()
        self.timer = nil
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            print("timer running")
            if Configuration.stopAt > Int(Date().timeIntervalSince1970) {
                self.fetchPrice(asset: asset)
            } else {
                self.timer?.invalidate()
            }
        }
    }
    
    private func fetchPrice(asset: MoneyAsset) {
        Task {
            let data = await self.loadTradingViewData(asset: asset)
            self.updateActivity(type: data)
        }
    }

    func updateActivity(type: MoneyAsset) {
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
                        price: "\(type.price ?? 0)",
                        symbol: type.symbol ?? "",
                        isIncrease: (type.change ?? 0) > 0
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
    }
    
    func search(text: String, screener: Screener) {
        guard text != "" else {
            DispatchQueue.main.async { self.searchResultList = [] }
            return
        }
        guard let url = URL(string: "\(baseUrl)/trading-view/search?query=\(text.uppercased())&screener=\(screener.rawValue)") else {
            DispatchQueue.main.async { self.searchResultList = [] }
            return
        }
        self.isSearching = true
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.searchResultList = []
                    self.isSearching = false
                }
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
                DispatchQueue.main.async {
                    self.searchResultList = []
                    self.isSearching = false
                }
                return
            }
            do {
                let object = try JSONDecoder().decode([MoneyAsset].self, from: data)
                DispatchQueue.main.async { 
                    self.searchResultList = object
                    self.isSearching = false
                }
            } catch let jsonError {
                print("URL: \(url.absoluteString) JSON error: \(jsonError)")
                DispatchQueue.main.async {
                    self.searchResultList = []
                    self.isSearching = false
                }
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
        let assetString = "\(asset.symbol ?? "")+\(asset.screener ?? "")+\(asset.exchange ?? "")+\(asset.desc ?? "")+\(asset.image ?? "")"
        if !currentFavorite.contains(assetString) {
            currentFavorite.append(assetString)
            Configuration.favoriteAssets = currentFavorite
        }
        self.loadData()
        self.addSymbol(asset: asset)
    }
    
    func removeFavoriateAsset(asset: MoneyAsset) {
        var currentFavorite = Configuration.favoriteAssets
        let assetString = "\(asset.symbol ?? "")+\(asset.screener ?? "")+\(asset.exchange ?? "")+\(asset.desc ?? "")+\(asset.image ?? "")"
        currentFavorite.removeAll {
            $0 == assetString
        }
        Configuration.favoriteAssets = currentFavorite
        self.loadData()
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
                    print("URL: \(url.absoluteString) JSON error: \(jsonError)")
                    con.resume(returning: [])
                }
            }.resume()
        }
    }
    
    func loadTradingViewData(asset: MoneyAsset) async -> MoneyAsset {
        guard let symbol = asset.symbol else { return asset }
        guard let url = URL(string: "\(baseUrl)/trading-view/symbol-data?symbol=\(symbol)")
        else { return asset }
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
                    let result = try JSONDecoder().decode(MoneyAsset.self, from: data)
                    if result.price != nil {
                        var newAsset = asset
                        newAsset.price = result.price
                        newAsset.desc = result.desc
                        newAsset.change = result.change
                        newAsset.volume = result.volume
                        newAsset.changePercentage = result.changePercentage
                        con.resume(returning: newAsset)
                    } else {
                        con.resume(returning: asset)
                    }
                } catch let jsonError {
                    print("URL: \(url.absoluteString) JSON error: \(jsonError)")
                    con.resume(returning: asset)
                }
            }.resume()
        }
    }
    
    func addSymbol(asset: MoneyAsset) {
        guard let url = URL(string: "\(baseUrl)/trading-view/add?symbol=\(asset.symbol ?? "")")
        else { return }
        URLSession.shared.dataTask(with: url) { data, response, error in
        }.resume()
    }
}

struct TradingViewPrice: Codable {
    var close: Double?
    var open: Double?
}

struct RecommenedListResponse: Codable {
    let items: [TradingViewItem]
}

struct TradingViewItem: Codable {
    let relatedSymbols: [TradingViewSymbol]
}

struct TradingViewSymbol: Codable, Identifiable, Equatable {
    let logoid: String?
    let symbol: String
    var id: String {
        return self.symbol
    }
}

extension String {
    func extractCurrencyPair() -> String {
        let pattern = "(BTCUSD|ETHUSD|[A-Z]{3}USD)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        
        if let match = regex?.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
            if let range = Range(match.range, in: self) {
                return String(self[range])
            }
        }
        return self
    }
}
