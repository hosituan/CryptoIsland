//
//  DynamicPriceIslandApp.swift
//  DynamicPriceIsland
//
//  Created by Ho Si Tuan on 24/07/2024.
//

import SwiftUI
import UIKit
import BackgroundTasks

@main
struct DynamicPriceIslandApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    init() {
//        registerBackgroundTasks()
    }
    @StateObject var viewModel = BitcoinTickerViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
        .backgroundTask(.appRefresh("com.yourapp.timer")) { _ in
            print("DO")
        }
    }
    
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Custom setup code here
        print("App did finish launching")
        UIApplication.shared.registerForRemoteNotifications()
        return true
    }
    
   
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print(tokenString)
    }
}
