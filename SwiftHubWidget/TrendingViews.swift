//
//  TrendingViews.swift
//  SwiftHubWidget
//
//  全部使用 iOS 14+ API，保证 15.4 可用
//

import SwiftUI
import WidgetKit

// MARK: - 兼容 iOS 17 的 widget 背景

extension View {
    @ViewBuilder
    func trendingBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            self.containerBackground(for: .widget) { Color(UIColor.systemBackground) }
        } else {
            self.background(Color(UIColor.systemBackground))
        }
    }
}

// MARK: - 工具

private let compactFormatter: NumberFormatter = {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.maximumFractionDigits = 1
    return f
}()

func compactStars(_ value: Int) -> String {
    if value >= 1000 {
        let k = Double(value) / 1000.0
        return (compactFormatter.string(from: NSNumber(value: k)) ?? "\(value)") + "k"
    }
    return "\(value)"
}

// MARK: - 单个仓库行

struct TrendingRow: View {
    let index: Int
    let repo: TrendingRepo
    var showsRank: Bool = true

    var body: some View {
        HStack(spacing: 6) {
            if showsRank {
                Text("\(index + 1)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .frame(width: 12, alignment: .leading)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(repo.fullName)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                if let desc = repo.description, !desc.isEmpty {
                    Text(desc)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 2)
            VStack(alignment: .trailing, spacing: 1) {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 7))
                        .foregroundColor(.yellow)
                    Text(compactStars(repo.stars))
                        .font(.system(size: 9, weight: .medium))
                }
                if let period = repo.currentPeriodStars, period > 0 {
                    Text("+\(period)")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.green)
                }
            }
        }
    }
}

// MARK: - 小尺寸

struct TrendingSmallView: View {
    let entry: TrendingEntry

    private var repo: TrendingRepo? { entry.repos.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 3) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.orange)
                Text("TRENDING")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer(minLength: 0)
            }

            if let repo = repo {
                Text(repo.fullName)
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .layoutPriority(1)

                if let desc = repo.description, !desc.isEmpty {
                    Text(desc)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.yellow)
                    Text(compactStars(repo.stars))
                        .font(.system(size: 10, weight: .semibold))
                    if let period = repo.currentPeriodStars, period > 0 {
                        Text("+\(period)")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.green)
                    }
                }
            } else {
                Spacer()
                Text(entry.isPlaceholder ? "Tap to load" : "No data")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(.horizontal, 2)
    }
}

// MARK: - 中 / 大尺寸

struct TrendingListView: View {
    let entry: TrendingEntry
    let maxRows: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 3) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.orange)
                Text("TRENDING TODAY")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer(minLength: 0)
                Text("GitHub")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }

            let repos = Array(entry.repos.prefix(maxRows))
            if repos.isEmpty {
                Spacer()
                Text(entry.isPlaceholder ? "数据加载中…" : "暂时没有数据")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                ForEach(Array(repos.enumerated()), id: \.element.id) { pair in
                    TrendingRow(index: pair.offset, repo: pair.element)
                    if pair.offset != repos.count - 1 {
                        Spacer(minLength: 0)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 2)
    }
}
