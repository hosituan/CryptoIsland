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
    @State private var subscribeType: MoneyAsset = .empty
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16, pinnedViews: [.sectionHeaders]) {
                if liveActivityManager.searchText.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                    Section {
                        if liveActivityManager.searchResultList.isEmpty {
                            Text("No results")
                                .font(.system(size: 14))
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ForEach(liveActivityManager.searchResultList) { item in
                                MoneyAssetItemView(type: item, buttonTitle: "Add", onTapAction: {
                                    liveActivityManager.addFavoriteAsset(asset: item)
                                    liveActivityManager.loadData()
                                    liveActivityManager.searchText = ""
                                })
                                .id(UUID())
                                .padding(.horizontal, 16)
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                        }
                    } header: {
                        Text("Search Result")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.9))
                    }
                }
                Section {
                    if liveActivityManager.favorites.isEmpty {
                        Text("No favorite symbols")
                            .font(.system(size: 14))
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(liveActivityManager.favorites) { item in
                            MoneyAssetItemView(type: item, buttonTitle: self.subscribeType == item ? "Unsubscribe" : "Subscribe", onTapAction: {
                                if self.subscribeType == item {
                                    self.subscribeType = .empty
                                    LiveActivityManager.shared.message = "Stopping..."
                                    LiveActivityManager.shared.endActivity(completion: { })
                                } else {
                                    LiveActivityManager.shared.message = "Starting..."
                                    LiveActivityManager.shared.startActivity(asset: item)
                                    self.subscribeType = item
                                }
                            })
                            .id(UUID())
                            .padding(.horizontal, 16)
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                } header: {
                    Text("Favorite")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.9))
                }
            }
            .padding(.bottom, 16)
            .searchable(text: $liveActivityManager.searchText)
            .disableAutocorrection(true)
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
            LiveActivityManager.shared.loadData()
        }
    }
}

struct MoneyAssetItemView: View {
    @State var type: MoneyAsset
    var buttonTitle: String = ""
    var onTapAction: (() -> Void)
    @State private var price: Double = 0
    @State var task: Task<Void, Never>? = nil
    var body: some View {
        HStack(spacing: 10) {
            AsyncImage(url: URL(string: type.getLogoUrl())) { image in
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
                Text(type.screener)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Text(type.symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                Text(type.desc ?? "")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(3)
            }
            
            Spacer()
            if let price = type.close {
                Text(price.asCurrency())
                    .font(.system(size: 14))
                    .padding(4)
                    .foregroundColor(.white)
                    .background((type.close ?? 0 >= type.open ?? 0) ? Configuration.upColor : Configuration.downColor)
                    .cornerRadius(5)
            } else {
                Text((type.close ?? 0).asCurrency())
                    .font(.system(size: 14))
                    .padding(4)
                    .foregroundColor(.white)
                    .background((type.close ?? 0 >= type.open ?? 0) ? Configuration.upColor : Configuration.downColor)
                    .cornerRadius(5)
                    .redacted(reason: .placeholder)
            }

            Button(action: {
                onTapAction()
            }, label: {
                Text(buttonTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(buttonTitle == "Unsubscribe" ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(5)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: true)
            })
        }
        .contentShape(.rect)
        .onAppear(perform: {
            loadData()
        })
        .onDisappear(perform: {
            self.task?.cancel()
        })
    }
    
    func loadData() {
        self.task = Task {
            self.type = await LiveActivityManager.shared.loadData(asset: self.type)
            self.loadData()
        }
    }
    

    
}

