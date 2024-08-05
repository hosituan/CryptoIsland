//
//  DynamicPriceIslandApp.swift
//  DynamicPriceIsland
//
//  Created by Ho Si Tuan on 24/07/2024.
//

import SwiftUI
import UIKit
import BackgroundTasks
import ActivityKit

@main
struct DynamicPriceIslandApp: App {
    init() {
        LiveActivityManager.shared.endActivity(completion: { })
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .accentColor(.black)
        }
    }
    
}
