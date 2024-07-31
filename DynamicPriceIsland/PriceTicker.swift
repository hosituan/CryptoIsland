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
    
    func getCoinBaseSymbol() -> String {
        return "\(self.name)-USD"
    }
    
    func getPrice(source: CryptoSource, completion: @escaping (String) -> Void) {
        let task = URLSession.shared.dataTask(with: getUrl(type: source)) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Invalid response or status code")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let data = json["data"] as? [String: Any],
                       let amount = data["amount"] as? String {
                        completion(amount)
                    } else if let data = json["price"] as? String {
                        completion(data)
                    }
                }
            } catch let jsonError {
                print("JSON error: \(jsonError.localizedDescription)")
            }
        }
        task.resume()
    }
    
    func getUrl(type: CryptoSource) -> URL {
        switch type {
        case .binance: 
            URL(string: "https://api.binance.com/api/v3/ticker/price?symbol=\(self.rawValue)")!
        case .coinbase:
            URL(string: "https://api.coinbase.com/v2/prices/\(self.getCoinBaseSymbol())/spot")!
        }
    }
}

enum CryptoSource {
    case binance
    case coinbase
}
