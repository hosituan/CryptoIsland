//
//  SettingsView.swift
//  DynamicPriceIsland
//
//  Created by Ho Si Tuan on 04/08/2024.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @ObservedObject var liveActivityManager: LiveActivityManager
    @State private var selectedUpColor = Color.green
    @State private var selectedDownColor = Color.red
    @State private var numberOfDecimal = 2
    @State private var stopAfter: Double = 1
    var body: some View {
        ScrollView(showsIndicators: false, content: {
            LazyVStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Increase color")
                        .font(.system(size: 16))
                    Spacer()

                    ColorPicker("", selection: $selectedUpColor)
                }
                .frame(height: 56)
                Divider()
                HStack {
                    Text("Decrease color")
                        .font(.system(size: 16))
                    Spacer()
                    ColorPicker("", selection: $selectedDownColor)
                }
                .frame(height: 56)
                Divider()
                HStack {
                    Text("Number of decimal")
                        .font(.system(size: 16))
                    Spacer()
                    Picker("", selection: $numberOfDecimal) {
                        ForEach(0..<4) { value in
                            Text("\(value)")
                                .tag(value)
                        }
                    }
                    .padding(.horizontal, 16)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(5)
                }
                .frame(height: 56)
                Divider()
                HStack {
                    Text("Automatically stop after")
                        .font(.system(size: 16))
                    Spacer()
                    Picker("", selection: $stopAfter) {
                        Text("Never").tag(0)
                        Text("1 minute").tag(0.017)
                        Text("15 minutes").tag(0.25)
                        Text("30 minutes").tag(0.5)
                        Text("1 hour").tag(1)
                        ForEach(2..<13) { value in
                            Text("\(value) hours")
                                .tag(value)
                        }
                    }
                    .padding(.horizontal, 16)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(5)
                }
                .frame(height: 56)
                Divider()
            }
            .padding(16)
            .ignoresSafeArea()
        })
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: self.selectedUpColor) { oldValue, newValue in
            Configuration.upColor = newValue
        }
        .onChange(of: self.selectedDownColor) { oldValue, newValue in
            Configuration.downColor = newValue
        }
        .onChange(of: self.numberOfDecimal) { oldValue, newValue in
            Configuration.priceDecimal = newValue
        }
        .onChange(of: self.stopAfter) { oldValue, newValue in
            Configuration.stopAfter = newValue
            if newValue > 0 {
                let mins = newValue * 60
                let newDate = Date().addingMinutes(Int(mins))
                LiveActivityManager.shared.setStopTime(time: newDate)
            }
        }
        .onAppear {
            self.selectedUpColor = Configuration.upColor
            self.selectedDownColor = Configuration.downColor
            self.stopAfter = Configuration.stopAfter
            self.numberOfDecimal = Configuration.priceDecimal
        }
    }
    
}


#Preview {
    NavigationStack {
        SettingsView(liveActivityManager: .init())
    }
}
