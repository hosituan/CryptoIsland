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
    @StateObject var manager = LiveActivityManager.shared
    var body: some View {
        TabView {
            NavigationStack {
                HomeScreenView(liveActivityManager: self.manager)
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            NavigationStack {
                SettingsView(liveActivityManager: self.manager)
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
                    .tint(.accentColor)
            }
        }
        .overlay(alignment: .center) {
            if let message = manager.message {
                CryptoProgressView(message: message)
                    .ignoresSafeArea()
            }
        }
        .accentColor(.primary)
    }
}



struct CryptoProgressView: View {
    var message: String
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(.black)
                    Text(message)
                        .foregroundColor(.black)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(5)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .background(Color.black.opacity(0.3))
        .ignoresSafeArea()
    }
}


extension Int {
    var nanoseconds: UInt64 {
        return UInt64(self) * 1_000_000_000
    }
}

extension Double {
    var nanoseconds: UInt64 {
        return UInt64(self * 1_000_000_000)
    }
}

#Preview {
    ContentView()
}
