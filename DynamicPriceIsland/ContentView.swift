//
//  ContentView.swift
//  DynamicPriceIsland
//
//  Created by Ho Si Tuan on 24/07/2024.
//

import SwiftUI
import Combine
import ActivityKit
import BackgroundTasks

struct ContentView: View {
    var body: some View {
        NavigationView {
            HomeScreenView()
        }
        .navigationViewStyle(.stack)
    }
}


struct HomeScreenView: View {
    @State private var showingAlert = false
    @State private var message: String?
    @State private var subscribeType: PriceTicker?
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(PriceTicker.allCases.indices, id: \.self) { index in
                    PriceItemView(type: PriceTicker.allCases[index], selected: self.subscribeType, onTapAction: {
                        if self.subscribeType == PriceTicker.allCases[index] {
                            self.subscribeType = nil
                            LiveActivityManager.shared.endActivity(dismissTimeInterval: -1)
                        } else {
                            LiveActivityManager.shared.startActivity(type: PriceTicker.allCases[index])
                            self.subscribeType = PriceTicker.allCases[index]
                        }
                    })

                    Divider()
                }
            }
            .padding(20)
        }
        .onChange(of: message, initial: false, {
            if message != nil {
                self.showingAlert = true
            }
        })
        .alert(message ?? "", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {
                message = nil
            }
        }
        .navigationTitle("Crypto Island")
    }
}

struct PriceItemView: View {
    var type: PriceTicker
    var selected: PriceTicker?
    var onTapAction: (() -> Void)
    @State private var price: Double = 0.0
    @State private var lastPrice: Double = 0.0
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    var body: some View {
        HStack(spacing: 10) {
            Image(type.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 36, height: 36)
            Text(type.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
            Spacer()
            Text(price.asCurrency())
                .font(.system(size: 14))
                .padding(4)
                .foregroundColor(.white)
                .background(price >= lastPrice ? Color.green : Color.red)
                .cornerRadius(5)
            Spacer()
            Button(action: {
                onTapAction()
            }, label: {
                Text(selected == type ? "Unsubscribe" : "Subscribe")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(selected == type ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(5)
            })
        }
        .contentShape(.rect)
        .onReceive(timer) { input in
            self.fetchPrice()
        }
    }
    
    private func fetchPrice() {
        guard let url = URL(string: "https://api.binance.com/api/v3/ticker/price?symbol=\(type.rawValue)") 
        else { return }
        let session = URLSession.shared
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                print("No data received")
                return
            }
            do {
                let tickerPrice = try JSONDecoder().decode(BitcoinPrice.self, from: data)
                self.lastPrice = self.price
                self.price = tickerPrice.price.toDouble()
            } catch {
                print("Failed to decode JSON: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
}
#Preview {
    ContentView()
}
