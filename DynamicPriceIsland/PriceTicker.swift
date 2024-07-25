//
//  PriceTicker.swift
//  DynamicPriceIsland
//
//  Created by Ho Si Tuan on 25/07/2024.
//

import Foundation

enum PriceTicker: String {
    case bitcoin = "BTCUSDT"
    var imageName: String {
        switch self {
        case .bitcoin: "bitcoin"
        }
    }
    var name: String {
        switch self {
        case .bitcoin: self.rawValue
        }
    }
}
