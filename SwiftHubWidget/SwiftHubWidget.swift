//
//  SwiftHubWidget.swift
//  SwiftHubWidget
//
//  GitHub 趋势榜小组件：只依赖公开接口，不读取登录态，
//  因此在免签（TrollStore）环境下也能正常工作。
//

import SwiftUI
import WidgetKit

struct TrendingWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: TrendingEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                TrendingSmallView(entry: entry)
            case .systemLarge:
                TrendingListView(entry: entry, maxRows: 8)
            default:
                TrendingListView(entry: entry, maxRows: 3)
            }
        }
        .trendingBackground()
        .widgetURL(URL(string: "swifthub://"))
    }
}

struct TrendingWidget: Widget {
    let kind: String = "TrendingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TrendingProvider()) { entry in
            TrendingWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("GitHub Trending")
        .description("每天的热门仓库，点按打开 SwiftHub。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct SwiftHubWidgetBundle: WidgetBundle {
    var body: some Widget {
        TrendingWidget()
    }
}
