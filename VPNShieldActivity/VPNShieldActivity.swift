//
//  VPNShieldActivity.swift
//  VPNShieldActivity
//
//  Created by Oleg Yakushin on 31/7/25.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
}

struct VPNShieldActivityEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text("Time:")
            Text(entry.date, style: .time)

            Text("Favorite Emoji:")
            Text(entry.configuration.favoriteEmoji)
        }
    }
}

struct VPNShieldActivity: Widget {
    let kind: String = "VPNShieldActivity"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            VPNShieldActivityEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

#Preview(as: .systemSmall) {
    VPNShieldActivity()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley)
    SimpleEntry(date: .now, configuration: .starEyes)
}
import ActivityKit
import WidgetKit
import SwiftUI

struct LiveBadge: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color(white: 0.95))
            )
    }
}


struct VPNLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: VPNActivityAttributes.self) { context in
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "network.badge.shield.half.filled")
                        .font(.system(size: 20))
                        .frame(width: 28, height: 28)
                        .foregroundStyle(.primary)
                        .padding(6)
                        .background(Circle().fill(Color(white: 0.96)))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.serviceName)
                            .font(.system(size: 15, weight: .semibold))
                            .lineLimit(1)
                        Text(context.state.startedAt, style: .timer)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer(minLength: 8)
                LiveBadge(text: context.state.isConnected ? "VPN включён" : "Подключение…")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .activityBackgroundTint(.white)
            .activitySystemActionForegroundColor(.primary) // цвет системных кнопок/линков
            .widgetURL(URL(string: "vpnshield://open")) // тап по баннеру откроет приложение

        } dynamicIsland: { context in
            // DYNAMIC ISLAND
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "lock.shield.fill")
                        .imageScale(.large)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.attributes.serviceName)
                            .font(.system(size: 15, weight: .semibold))
                        Text(context.state.serverName.isEmpty ? "Без сервера" : context.state.serverName)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    LiveBadge(text: context.state.isConnected ? "VPN включён" : "Подключение…")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    // Кнопка "Отключить VPN" — откроет приложение по диплинку
                    Link(destination: URL(string: "vpnshield://disconnect")!) {
                        Label("Отключить VPN", systemImage: "power")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.95)))
                    }
                }
            } compactLeading: {
                Image(systemName: "lock.shield.fill")
                    .imageScale(.small)
            } compactTrailing: {
                // маленький бейджик
                Text("VPN")
                    .font(.system(size: 12, weight: .bold))
            } minimal: {
                Image(systemName: "lock.shield")
            }
        }
    }
}
