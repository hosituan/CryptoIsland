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
        ActivityConfiguration(for: TickerAttribute.self) { context in
            HStack {
                Image(context.state.symbol.lowercased())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                Text(context.state.symbol)
                    .font(.system(size: 14))
                Spacer()
                Text("\(context.state.price.toDouble().asCurrency())")
                    .padding(2)
                    .font(.system(size: 14))
                    .padding(.horizontal, 10)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(.white)
                    .background(context.state.isIncrease ? Configuration.upColor : Configuration.downColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal)

        } dynamicIsland: { context in
            DynamicIsland {
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
                    Image(context.state.symbol.lowercased())
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                    Text(context.state.symbol)
                    Spacer()
                }
            } compactTrailing: {
                HStack {
                    Spacer()
                    Text("\(context.state.price.toDouble().asCurrency())")
                        .padding(2)
                        .padding(.horizontal, 2)
                        .minimumScaleFactor(0.5)
                        .background(context.state.isIncrease ? Configuration.upColor : Configuration.downColor)
                        .cornerRadius(12)
                }
            } minimal: {
                Text("\(context.state.price)")
                    .padding(2)
                    .padding(.horizontal, 2)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(.white)
                    .background(context.state.isIncrease ? Configuration.upColor : Configuration.downColor)
                    .cornerRadius(12)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}
