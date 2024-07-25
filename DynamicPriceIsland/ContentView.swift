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
        VStack {
            HomeScreenView()
        }
        .padding()
    }
}


struct HomeScreenView: View {
    var body: some View {
        VStack {
            Text("Bitcoin Ticker")
                .font(.largeTitle)
                .padding()
            
            HStack {
                Text("BTC/USD:")
                    .font(.headline)
                Text("$")
                    .font(.headline)
                    .bold()
            }
            .padding()
            .background(Color.black.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Button(action: {
                LiveActivityManager.shared.startActivity()
            }) {
                Text("Start Live Activity")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            Button(action: {
                LiveActivityManager.shared.updateActivity(delay: 5, alert: true)
            }, label: {
                Text("Update Activity")
            })
            
            Button(action: {
                LiveActivityManager.shared.endActivity(dismissTimeInterval: -1)
            }, label: {
                Text("End Activity")
            })
        }

    }
}

#Preview {
    ContentView()
}
