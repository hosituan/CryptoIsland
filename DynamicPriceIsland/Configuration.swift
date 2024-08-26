//
//  Configuration.swift
//  DynamicPriceIsland
//
//  Created by Ho Si Tuan on 04/08/2024.
//

import Foundation
import SwiftUI
import UIKit

struct Configuration {
    static let userDefault = UserDefaults(suiteName: "group.com.swiftys.com.DynamicPriceIsland")!
    static var upColor: Color {
        get {
            let colorData = userDefault.data(forKey: "upColor") ?? .init()
            return Color(uiColor: UIColor.color(data: colorData) ?? .green)
        }
        set {
            let colorData = UIColor(newValue).encode()
            userDefault.setValue(colorData, forKey: "upColor")
        }
    }
    static var downColor: Color {
        get {
            let colorData = userDefault.data(forKey: "downColor") ?? .init()
            return Color(uiColor: UIColor.color(data: colorData) ?? .red)
        }
        set {
            let colorData = UIColor(newValue).encode()
            userDefault.setValue(colorData, forKey: "downColor")
        }
    }
    static var priceDecimal: Int {
        get {
            return userDefault.integer(forKey: "priceDecimal")
        }
        set {
            userDefault.setValue(newValue, forKey: "priceDecimal")
        }
    }
    static var stopAfter: Double {
        get {
            return userDefault.double(forKey: "stopAfter")
        }
        set {
            userDefault.setValue(newValue, forKey: "stopAfter")
        }
    }
    
    static var stopAt: Int {
        get {
            return userDefault.integer(forKey: "stopAt")
        }
        set {
            userDefault.setValue(newValue, forKey: "stopAt")
        }
    }
    
    static var favoriteAssets: [String] {
        get {
            return Array(Set((userDefault.string(forKey: "favoriteAsset")?.components(separatedBy: "|") ?? [])))
        }
        set {
            userDefault.setValue(newValue.joined(separator: "|"), forKey: "favoriteAsset")
        }
    }
    
    static func saveImage(symbol: String, image: UIImage?) {
        guard let image else { return }
        userDefault.setValue(image.jpegData(compressionQuality: 1), forKey: symbol)
    }
    
    static func getImage(symbol: String) -> UIImage? {
        return UIImage(data: userDefault.data(forKey: symbol) ?? Data())
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}


extension Color {
    func toHex() -> String? {
        let components = self.cgColor?.components
        let r: CGFloat
        let g: CGFloat
        let b: CGFloat
        let a: CGFloat
        
        if components?.count == 2 {
            r = components?[0] ?? 0.0
            g = components?[0] ?? 0.0
            b = components?[0] ?? 0.0
            a = components?[1] ?? 0.0
        } else {
            r = components?[0] ?? 0.0
            g = components?[1] ?? 0.0
            b = components?[2] ?? 0.0
            a = components?[3] ?? 0.0
        }
        
        return String(
            format: "#%02X%02X%02X%02X",
            Int(r * 255),
            Int(g * 255),
            Int(b * 255),
            Int(a * 255)
        )
    }
}



extension UIColor {
    class func color(data: Data) -> UIColor? {
        return (try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data))
    }

    func encode() -> Data {
        return (try? NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)) ?? .init()
    }
}
