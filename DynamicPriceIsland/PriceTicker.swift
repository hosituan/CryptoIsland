//
//  PriceTicker.swift
//  DynamicPriceIsland
//
//  Created by Ho Si Tuan on 25/07/2024.
//

import Foundation

enum PriceTicker: String, CaseIterable {
    case bitcoin = "BTCUSDT"
    case eth = "ETHUSDT"
    var imageName: String {
        switch self {
        case .bitcoin: "bitcoin"
        case .eth: "eth"
        }
    }
    var name: String {
        switch self {
        case .bitcoin: "BTC"
        case .eth: "ETH"
        }
    }
}
