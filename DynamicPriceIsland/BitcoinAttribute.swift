//
//  BitcoinAttribute.swift
//  DynamicPriceIsland
//
//  Created by Ho Si Tuan on 24/07/2024.
//

import Foundation
import ActivityKit

struct TickerAttribute: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var image: String
        var price: String
        var symbol: String
        var isIncrease: Bool
    }
    
    var name: String
}

