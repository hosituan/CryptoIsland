//
//  Extension+.swift
//  DynamicPriceIsland
//
//  Created by Ho Si Tuan on 25/07/2024.
//

import Foundation
extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
    func toMeter() -> Double {
        return self * 0.3048
    }
    
    func toFeet() -> Double {
        return self * 3.28084
    }
    
    func roundedString(toPlaces places: Int) -> String {
        let divisor = pow(10.0, Double(places))
        return String(format: "%.\(places)f", (self * divisor).rounded() / divisor)
    }
    
}

extension String {
    func toDouble() -> Double {
        return Double(self) ?? 0
    }
    
    func rounded(toPlaces places: Int) -> String {
        var array = self.components(separatedBy: ".")
        let sur = String(array.last?.prefix(places) ?? "")
        array.removeLast()
        array.append(sur)
        return array.joined(separator: ".")
    }
}

extension Date {
    func addingMinutes(_ minutes: Int) -> Date {
        return Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? Date()
    }
}

extension Double {
    func asCurrency(locale: Locale = Locale.current, currencyCode: String? = nil) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.currencyCode = currencyCode
        formatter.minimumFractionDigits = Configuration.priceDecimal
        formatter.maximumFractionDigits = Configuration.priceDecimal
        
        return formatter.string(from: NSNumber(value: self)) ?? ""
    }
}
