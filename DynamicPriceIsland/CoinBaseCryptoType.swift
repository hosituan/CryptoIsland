//
//  CoinBaseCryptoType.swift
//  DynamicPriceIsland
//
//  Created by Ho Si Tuan on 04/08/2024.
//

import Foundation

struct MoneyAsset: Codable, Identifiable, Equatable {
    var id: String { "\(symbol)_\(screener)_\(exchange)" }
    let symbol: String
    let screener: String
    let exchange: String
    var open: Double?
    var close: Double?
    var image: String?
    var desc: String?
    static let empty: MoneyAsset = .init(symbol: "", screener: "", exchange: "", open: 0, close: 0, image: "", desc: "")
    
    func getLogoUrl() -> String {
        return "https://s3-symbol-logo.tradingview.com/\(self.image ?? "").svg"
    }
}

struct MoneyAssetResponse: Codable {
    let success: Bool
    let data: MoneyAsset
}
