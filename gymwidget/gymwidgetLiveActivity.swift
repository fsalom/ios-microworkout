//
//  gymwidgetLiveActivity.swift
//  gymwidget
//
//  Created by Fernando Salom Carratala on 7/2/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct gymwidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct gymwidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: gymwidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension gymwidgetAttributes {
    fileprivate static var preview: gymwidgetAttributes {
        gymwidgetAttributes(name: "World")
    }
}

extension gymwidgetAttributes.ContentState {
    fileprivate static var smiley: gymwidgetAttributes.ContentState {
        gymwidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: gymwidgetAttributes.ContentState {
         gymwidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: gymwidgetAttributes.preview) {
   gymwidgetLiveActivity()
} contentStates: {
    gymwidgetAttributes.ContentState.smiley
    gymwidgetAttributes.ContentState.starEyes
}
