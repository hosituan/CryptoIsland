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
    @EnvironmentObject var viewModel: BitcoinTickerViewModel
    var body: some View {
        VStack {
            Text("Bitcoin Ticker")
                .font(.largeTitle)
                .padding()
            
            BitcoinTickerView(viewModel: viewModel)
            
            Button(action: {
                viewModel.startLiveActivity()
            }) {
                Text("Start Live Activity")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }

    }
}


class BitcoinTickerViewModel: ObservableObject {
    @Published var price: String = "Loading..."
    private var cancellables = Set<AnyCancellable>()
    @Published var activity: Activity<BitcoinTickerAttributes>? = nil
    
    init() {
        registerBackgroundTasks()
    }
    

    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.yourapp.timer", using: nil) { task in
            self.handleTimerTask(task: task as! BGProcessingTask)
        }
    }
    
    func handleTimerTask(task: BGProcessingTask) {
        task.expirationHandler = {
            // Clean up when the task expires
        }

        // Start a new timer or update the existing one
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            self.updateLiveActivity(with: String(Int.random(in: 0..<1000)))
        })

        task.setTaskCompleted(success: true)
    }
    


    
    func scheduleBackgroundTask() {
        let request = BGProcessingTaskRequest(identifier: "com.yourapp.timer")
        request.requiresNetworkConnectivity = true
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule background task: \(error.localizedDescription)")
        }
    }

    
    func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let activityAttributes = BitcoinTickerAttributes()
        let initialContentState = BitcoinTickerAttributes.ContentState(price: "Loading...", imageName: "bitcoin")
        
        do {
            activity = try Activity<BitcoinTickerAttributes>.request(
                attributes: activityAttributes,
                content: .init(state: initialContentState, staleDate: nil),
                pushType: .token)
        } catch {
            print("Failed to start Live Activity: \(error.localizedDescription)")
        }
        fetchBitcoinPrice()
        UIApplication.shared.beginBackgroundTask(withName: "com.yourapp.timer")
        scheduleBackgroundTask()
        
    }
    
    func stopActivity() {
        Task {
            let contentState = BitcoinTickerAttributes.ContentState(price: "Ending...", imageName: "bitcoin")
            await activity?.end(using: contentState, dismissalPolicy: .immediate)
        }
    }
    
    func updateLiveActivity(with price: String) {
        Task {
            await activity?.update(using: .init(price: price, imageName: "bitcoin"))
        }
    }
    
    func fetchBitcoinPrice() {
        guard let url = URL(string: "https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT") else {
            return
        }
        self.price = "\(Int.random(in: 0..<1000))"
        self.updateLiveActivity(with: "$" + price.toDouble().roundedString(toPlaces: 2))
    }
}

struct BitcoinTickerView: View {
    @ObservedObject var viewModel: BitcoinTickerViewModel
    
    var body: some View {
        HStack {
            Text("BTC/USD:")
                .font(.headline)
            Text("$" + viewModel.price.toDouble().roundedString(toPlaces: 2))
                .font(.headline)
                .bold()
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .foregroundColor(.white)
        .cornerRadius(10)
    }
}


extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
    func toMeter() -> Double {
        return self * 0.3048
    }
    
    func toFeet() -> Double {
        return self * 3.28084
    }
    
    func roundedString(toPlaces places: Int) -> String {
        let divisor = pow(10.0, Double(places))
        return String(format: "%.\(places)f", (self * divisor).rounded() / divisor)
    }
}

extension String {
    func toDouble() -> Double {
        return Double(self) ?? 0
    }
}

#Preview {
    ContentView()
}
