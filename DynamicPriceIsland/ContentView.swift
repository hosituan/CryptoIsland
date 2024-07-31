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
                            LiveActivityManager.shared.endActivity()
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
        .onAppear {
            subscribeType = LiveActivityManager.shared.getSavedActivity()
            if let subscribeType {
                LiveActivityManager.shared.startActivity(type: subscribeType)
            }
        }
    }
}

struct PriceItemView: View {
    var type: PriceTicker
    var selected: PriceTicker?
    var onTapAction: (() -> Void)
    @State private var price: Double = 0.0
    @State private var lastPrice: Double = 0.0
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
        .onAppear(perform: {
            self.fetchPrice()
        })
    }
    
    private func fetchPrice() {
        self.type.getPrice(source: .coinbase) { tickerPrice in
            self.lastPrice = self.price
            self.price = tickerPrice.toDouble()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                self.fetchPrice()
            })
        }
    }
    
}
#Preview {
    ContentView()
}
