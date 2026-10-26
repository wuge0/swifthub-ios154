//
//  TrendingProvider.swift
//  SwiftHubWidget
//

import WidgetKit
import SwiftUI

struct TrendingProvider: TimelineProvider {

    func placeholder(in context: Context) -> TrendingEntry {
        .placeholder()
    }

    func getSnapshot(in context: Context, completion: @escaping (TrendingEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder())
            return
        }
        TrendingService.fetch { repos in
            completion(TrendingEntry(date: Date(),
                                     repos: repos.isEmpty ? TrendingEntry.placeholder().repos : repos,
                                     isPlaceholder: repos.isEmpty))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TrendingEntry>) -> Void) {
        TrendingService.fetch { repos in
            let entry = TrendingEntry(date: Date(), repos: repos, isPlaceholder: repos.isEmpty)
            // 趋势榜每天更新一次，30 分钟刷新足够，也能避免触发接口限流
            let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }
}
