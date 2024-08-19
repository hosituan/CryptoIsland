//
//  CoinBaseCryptoType.swift
//  DynamicPriceIsland
//
//  Created by Ho Si Tuan on 04/08/2024.
//

import Foundation

struct MoneyAsset: Codable, Identifiable, Equatable {
    var id: String { "\(symbol ?? "")_\(screener ?? "")_\(exchange ?? "")" }
    var symbol: String?
    var screener: String?
    var exchange: String?
    var open: Double?
    var close: Double?
    var image: String?
    var desc: String?
    var change: Double?
    var changePercentage: Double?
    var price: Double?
    var volume: Double?
    static let empty: MoneyAsset = .init(symbol: "", screener: "", exchange: "", open: 0, close: 0, image: "", desc: "")
    
    func getLogoUrl() -> String {
        return "https://s3-symbol-logo.tradingview.com/\(self.image ?? "").svg"
    }
    
    func getScreener() -> Screener {
        return Screener(rawValue: screener ?? "") ?? .crypto
    }
}

struct MoneyAssetResponse: Codable {
    let success: Bool
    let data: MoneyAsset
}
 
