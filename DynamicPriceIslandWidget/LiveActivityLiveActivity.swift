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
                Image(uiImage: Configuration.getImage(symbol: context.state.symbol) ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .cornerRadius(12)
                Text(context.state.symbol)
                    .font(.system(size: 14))
                Spacer()
                Text("\(context.state.price.toDouble().asCurrency())")
                    .padding(2)
                    .font(.system(size: 16))
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
                    HStack {
                        Image(uiImage: Configuration.getImage(symbol: context.state.symbol) ?? UIImage())
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .cornerRadius(12)
                        Text(context.state.symbol.replacingOccurrences(of: "USDT", with: "").replacingOccurrences(of: "USDC", with: "").replacingOccurrences(of: "USD", with: ""))
                            .font(.system(size: 12))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.price.toDouble().asCurrency())")
                        .padding(2)
                        .font(.system(size: 16))
                        .padding(.horizontal, 10)
                        .minimumScaleFactor(0.5)
                        .foregroundColor(.white)
                        .background(context.state.isIncrease ? Configuration.upColor : Configuration.downColor)
                        .cornerRadius(12)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("")
                }
            } compactLeading: {
                HStack {
                    Image(uiImage: Configuration.getImage(symbol: context.state.symbol) ?? UIImage())
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .cornerRadius(12)
                    Text(context.state.symbol)
                        .font(.system(size: 12))
                    Spacer()
                }
            } compactTrailing: {
                HStack {
                    Spacer()
                    Text("\(context.state.price.toDouble().asCurrency())")
                        .padding(2)
                        .font(.system(size: 16))
                        .padding(.horizontal, 2)
                        .minimumScaleFactor(0.5)
                        .background(context.state.isIncrease ? Configuration.upColor : Configuration.downColor)
                        .cornerRadius(12)
                }
            } minimal: {
                Image(uiImage: Configuration.getImage(symbol: context.state.symbol) ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .background(context.state.isIncrease ? Configuration.upColor : Configuration.downColor)
                    .frame(width: 24, height: 24)
                    .cornerRadius(12)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}
