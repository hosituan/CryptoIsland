//
//  CoinBaseCryptoType.swift
//  DynamicPriceIsland
//
//  Created by Ho Si Tuan on 04/08/2024.
//

import Foundation

struct CoinBaseCryptoListResponse: Codable {
    let data: [CoinBaseCryptoType]
}

struct CoinBaseCryptoType: Codable, Identifiable, Equatable {
    var id: String {
        return asset_id
    }
    let asset_id: String
    let code: String
    let name: String
    let color: String
    let type: String
    
    static let empty: CoinBaseCryptoType = .init(asset_id: "", code: "", name: "", color: "", type: "")
}

struct CoinBaseCrypto: Codable {
    let data: CoinbaseCryptoData
}

struct CoinbaseCryptoData: Codable, Identifiable, Equatable {
    var id: String { base }
    let amount: String
    let base: String
    let currency: String
}

struct Crypto: Codable, Identifiable, Equatable {
    var id: String { code }
    let code: String
    let price: Double
    let image: String
    let name: String
    static let empty: Crypto = .init(code: "", price: 0, image: "", name: "")
}

struct CoinGecko: Codable {
    let id, symbol, name: String
    let image: String
    var total_volume, high_24h, low_24h: Double?
    let current_price: Double
    var last_updated: String?
    
    func toCrypto() -> Crypto {
        return Crypto(code: self.symbol.uppercased(), price: self.current_price, image: self.image, name: self.name)
    }
    
}
