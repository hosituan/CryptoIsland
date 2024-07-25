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
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(PriceTicker.allCases.indices, id: \.self) { index in
                    Button(action: {
                        LiveActivityManager.shared.startActivity(type: PriceTicker.allCases[index])
                        self.message = "Subscribed \(PriceTicker.allCases[index].rawValue).\nPlease go home to enjoy Price Island!"
                    }, label: {
                        HStack(spacing: 10) {
                            Image(PriceTicker.allCases[index].imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 36, height: 36)

                            Text(PriceTicker.allCases[index].name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .contentShape(.rect)
                    })

                    Divider()
                }
                Button(action: {
                    
                }, label: {
                    HStack {
                        Spacer()
                        Text("Stop Price Ticker")
                            .font(.system(size: 16, weight: .semibold))
                            .padding(16)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        Spacer()
                    }
                    .contentShape(.rect)
                    .onTapGesture {
                        LiveActivityManager.shared.endActivity(dismissTimeInterval: -1)
                    }
                })
                .padding(.vertical)
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

#Preview {
    ContentView()
}
