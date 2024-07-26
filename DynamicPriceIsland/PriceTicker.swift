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
    case bnb = "BNBUSDT"
    case xrp = "XRPUSDT"
    case sol = "SOLUSDT"
    var imageName: String {
        switch self {
        case .bitcoin: "bitcoin"
        case .eth: "eth"
        case .bnb: "bnb"
        case .xrp: "xrp"
        case .sol: "sol"
        }
    }
    var name: String {
        switch self {
        case .bitcoin: "BTC"
        case .eth: "ETH"
        case .bnb: "BNB"
        case .xrp: "XRP"
        case .sol: "SOL"
        }
    }
}
