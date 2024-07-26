//
//  LiveActivityLiveActivity.swift
//  LiveActivity
//
//  Created by guoxingxu on 2024/1/30.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct LiveActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BitcoinTickerAttributes.self) { context in
            HStack {
                Image(PriceTicker(rawValue: context.state.symbol)?.imageName ?? "")
                Text(PriceTicker(rawValue: context.state.symbol)?.rawValue ?? "")
            }

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("\(context.state.price.toDouble().asCurrency())")
                }
            } compactLeading: {
                HStack {
                    Image(PriceTicker(rawValue: context.state.symbol)?.imageName ?? "")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                    Text(PriceTicker(rawValue: context.state.symbol)?.name ?? "")
                    Spacer()
                }
            } compactTrailing: {
                HStack {
                    Spacer()
                    Text("\(context.state.price.toDouble().asCurrency())")
                        .padding(2)
                        .padding(.horizontal, 2)
                        .minimumScaleFactor(0.5)
                        .background(context.state.isIncrease ? Color.green : Color.red)
                        .cornerRadius(12)
                }
            } minimal: {
                Text("\(context.state.price)")
                    .padding(2)
                    .padding(.horizontal, 2)
                    .minimumScaleFactor(0.5)
                    .background(context.state.isIncrease ? Color.green : Color.red)
                    .cornerRadius(12)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}
