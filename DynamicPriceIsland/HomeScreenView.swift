//
//  HomeScreenView.swift
//  DynamicPriceIsland
//
//  Created by Ho Si Tuan on 04/08/2024.
//

import Foundation
import SwiftUI

struct HomeScreenView: View {
    @ObservedObject var liveActivityManager: LiveActivityManager
    @State private var showingAlert = false
    @State private var message: String?
    @State private var subscribeType: Crypto = .empty
    @State private var searchText = ""
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(liveActivityManager.coinList) { item in
                    CoinbaseItemView(type: item, selected: $subscribeType, onTapAction: {
                        if self.subscribeType == item {
                            self.subscribeType = .empty
                            LiveActivityManager.shared.message = "Stopping..."
                            LiveActivityManager.shared.endActivity(completion: { })
                        } else {
                            LiveActivityManager.shared.message = "Starting..."
                            LiveActivityManager.shared.startActivity(code: item.code)
                            self.subscribeType = item
                        }
                    })
                    
                    Divider()
                }
            }
            .padding(16)
            .searchable(text: $searchText)
        }
        .onChange(of: message, initial: false, {
            if message != nil {
                self.showingAlert = true
            }
        })
        .onChange(of: searchText, { oldValue, newValue in
            let trimmed = newValue.trimmingCharacters(in: .whitespaces)
            if trimmed != "" {
                LiveActivityManager.shared.coinList = LiveActivityManager.shared.originalList.filter({
                    $0.code.contains(trimmed) || $0.name.contains(trimmed)
                })
            } else {
                LiveActivityManager.shared.coinList = LiveActivityManager.shared.originalList
            }
        })
        .alert(message ?? "", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {
                message = nil
            }
        }
        .navigationTitle("Crypto Island")
        .onAppear {
            LiveActivityManager.shared.getCoinList()
        }
    }
}

struct CoinbaseItemView: View {
    var type: Crypto
    @Binding var selected: Crypto
    var onTapAction: (() -> Void)
    @State private var price: Double = 0.0
    @State private var lastPrice: Double = 0.0
    @State private var isIncrease = true
    var body: some View {
        HStack(spacing: 10) {
            AsyncImage(url: URL(string: type.image)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 36, height: 36)
                    .cornerRadius(18)
            }
            VStack(alignment: .leading) {
                Text(type.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                Text(type.code)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            Text(price.asCurrency())
                .font(.system(size: 14))
                .padding(4)
                .foregroundColor(.white)
                .background(isIncrease ? Configuration.upColor : Configuration.downColor)
                .cornerRadius(5)
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
            self.getPrice()
        })
    }
    
    func getPrice() {
        LiveActivityManager.shared.getPrice(code: self.type.code) { price in
            if self.lastPrice.asCurrency() != self.price.asCurrency() {
                self.isIncrease = self.price >= self.lastPrice
            }
            self.lastPrice = self.price
            self.price = Double(price) ?? 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                self.getPrice()
            })
        }
    }
    
}

