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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
}


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        LiveActivityManager.shared.getPushToStartToken()
        observeActivityPushToken()
        return true
    }
    
    func observeActivityPushToken() {
        Task {
            for await activityData in Activity<BitcoinTickerAttributes>.activityUpdates {
                Task {
                    for await tokenData in activityData.pushTokenUpdates {
                        let token = tokenData.map {String(format: "%02x", $0)}.joined()
                        print("Activity:\(activityData.id) Push token: \(token)")
                    }
                }
            }
        }
    }
}
