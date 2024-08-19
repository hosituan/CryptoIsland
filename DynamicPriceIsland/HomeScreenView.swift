//
//  HomeScreenView.swift
//  DynamicPriceIsland
//
//  Created by Ho Si Tuan on 04/08/2024.
//

import Foundation
import SwiftUI


struct ScreenerView: View {
    var screener: Screener
    var selected: Screener
    var body: some View {
        Text(screener.title)
            .font(.system(size: 14))
            .foregroundColor(screener == selected ? .white : Color.black)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(screener == selected ? Color.black.cornerRadius(5) : Color.white.cornerRadius(5))
            .borderRadius(5, color: Color.black)
            .cornerRadius(5)
            .contentShape(.rect)
            .clipped()
    }
}

struct BorderRadius: ViewModifier {
    var radius: CGFloat
    var color: Color
    var width: CGFloat
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(color, lineWidth: width)
                    .background(Color.clear)
            )
            .padding(width)
    }
}


extension View {
    func borderRadius(_ radius: CGFloat, color: Color, width: CGFloat = 1) -> some View {
        self.modifier(BorderRadius(radius: radius, color: color, width: width))
            .padding(.horizontal, 1)
    }
}



struct HomeScreenView: View {
    @ObservedObject var liveActivityManager: LiveActivityManager
    @State private var showingAlert = false
    @State private var message: String?
    @State private var subscribeType: MoneyAsset = .empty
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16, pinnedViews: [.sectionHeaders]) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(Screener.allCases) { screener in
                            ScreenerView(screener: screener, selected: liveActivityManager.screener)
                                .onTapGesture {
                                    liveActivityManager.screener = screener
                                }
                                .id(UUID())
                        }
                    }
                    .padding(.horizontal, 16)
                }
                if liveActivityManager.searchText.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                    Section {
                        if liveActivityManager.isSearching {
                            Text("Searching...")
                                .font(.system(size: 14))
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else if liveActivityManager.searchResultList.isEmpty {
                            Text("No results")
                                .font(.system(size: 14))
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ForEach(liveActivityManager.searchResultList) { item in
                                MoneyAssetItemView(asset: item, buttonTitle: "Add", onTapAction: {
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
                            MoneyAssetItemView(asset: item, buttonTitle: self.subscribeType == item ? "Unsubscribe" : "Subscribe", onTapAction: {
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
    var asset: MoneyAsset
    @State private var type: MoneyAsset = .empty
    var buttonTitle: String = ""
    var onTapAction: (() -> Void)
    @State private var price: Double = 0
    @State var task: Task<Void, Never>? = nil
    @State var showingOptions = false
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
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
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("\(type.screener ?? "")")
                        .font(.system(size: 12))
                        .lineLimit(1)
                        .fixedSize()
                        .foregroundColor(.gray)
                    Text("\(type.exchange?.uppercased() ?? "")")
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                        .fixedSize()
                    Spacer()
                }
                Text(type.symbol ?? "")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                Text(type.desc ?? "")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(3)
            }
            
            Spacer()
            if buttonTitle != "Add" {
                if let price = type.price {
                    Text(price.asCurrency())
                        .font(.system(size: 14))
                        .padding(4)
                        .foregroundColor(.white)
                        .background((type.close ?? 0 >= type.open ?? 0) ? Configuration.upColor : Configuration.downColor)
                        .cornerRadius(5)
                } else {
                    Text((type.price ?? 0).asCurrency())
                        .font(.system(size: 14))
                        .padding(4)
                        .foregroundColor(.white)
                        .background((type.close ?? 0 >= type.open ?? 0) ? Configuration.upColor : Configuration.downColor)
                        .cornerRadius(5)
                        .redacted(reason: .placeholder)
                }
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
            })
        }
        .contentShape(.rect)
        .onAppear(perform: {
            self.type = self.asset
        })
        .onReceive(timer) { input in
            self.loadData()
        }
        .onTapGesture {
            showingOptions.toggle()
        }
        .actionSheet(isPresented: $showingOptions) {
            ActionSheet(
                title: Text("Action"),
                buttons: [
                    .default(Text("Refresh")) {
                        self.loadData()
                    },
                    .destructive(Text("Delete")) {
                        self.delete()
                    },
                    .cancel(Text("Cancel"))
                ]
            )
        }
    }
    
    func loadData() {
        guard buttonTitle != "Add" else { return }
        Task {
            self.type = await LiveActivityManager.shared.loadTradingViewData(asset: self.asset)
        }
    }
    
    func delete() {
        LiveActivityManager.shared.removeFavoriateAsset(asset: self.type)
    }
}

