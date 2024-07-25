//
//  BitcoinAttribute.swift
//  DynamicPriceIsland
//
//  Created by Ho Si Tuan on 24/07/2024.
//

import Foundation
import ActivityKit

struct BitcoinPrice: Codable {
    let symbol: String
    let price: String
}

struct BitcoinTickerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var price: String
        var imageName: String
    }
    
    var name = "BitcoinTicker"
    
}

