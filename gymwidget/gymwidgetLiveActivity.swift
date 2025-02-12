//
//  gymwidgetLiveActivity.swift
//  gymwidget
//
//  Created by Fernando Salom Carratala on 7/2/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct GymWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
    }

    // Fixed non-changing properties about your activity go here!
    var startDate: Date
}

struct LiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GymWidgetAttributes.self)     { context in
            VStack(alignment: .center, spacing: 0) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .resizable()
                        .frame(width: 25, height: 25)
                        .clipShape(Circle())
                    Text("Este es el tiempo que llevas fuera:")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.white)
                    Spacer()
                }
                Text(context.attributes.startDate, style: .timer)
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .frame(minWidth: 0, maxWidth: .infinity)
            }
            .padding()
            .activityBackgroundTint(.black)
            .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    EmptyView()
                }
                DynamicIslandExpandedRegion(.trailing) {
                    EmptyView()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.attributes.startDate, style: .timer)
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            } compactLeading: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .resizable()

                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
            } compactTrailing: {
                Text(context.attributes.startDate, style: .timer)
                    .frame(width: 46)
            } minimal: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.orange)
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
            }
            .keylineTint(Color.red)
        }
    }
}

#Preview("Notification", as: .content, using: GymWidgetAttributes.init(startDate: .now)) {
    LiveActivityWidget()
} contentStates: {
    GymWidgetAttributes.ContentState.init()
}
