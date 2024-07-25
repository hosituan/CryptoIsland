//
//  DynamicPriceIslandWidgetLiveActivity.swift
//  DynamicPriceIslandWidget
//
//  Created by Ho Si Tuan on 24/07/2024.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct DynamicPriceIslandWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var emoji: String
    }

    var name: String
}

struct DynamicPriceIslandWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BitcoinTickerAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
      
                }
                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 3){
                        Text("Title")
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 4)
                    .padding(.vertical,3)
                    .background(.green)
                    .cornerRadius(4)
                }
            } compactLeading: {
                HStack{
                    Image("bitcoin")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                    Text("BTC/USD")
                }
            } compactTrailing: {
                Text(context.state.price)
                    .font(.subheadline)
                    .padding(.horizontal, 8)
                    .padding(.vertical,3)
                    .background(.green)
                    .cornerRadius(12)
            } minimal: {
                
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension DynamicPriceIslandWidgetAttributes {
    fileprivate static var preview: DynamicPriceIslandWidgetAttributes {
        DynamicPriceIslandWidgetAttributes(name: "World")
    }
}

extension DynamicPriceIslandWidgetAttributes.ContentState {
    fileprivate static var smiley: DynamicPriceIslandWidgetAttributes.ContentState {
        DynamicPriceIslandWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: DynamicPriceIslandWidgetAttributes.ContentState {
         DynamicPriceIslandWidgetAttributes.ContentState(emoji: "🤩")
     }
}

