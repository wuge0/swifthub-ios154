//
//  TrendingModels.swift
//  SwiftHubWidget
//
//  Trending 数据结构（与 SwiftHub 主 App 使用的 gitterapp 接口一致）
//

import Foundation
import WidgetKit

struct TrendingRepo: Codable, Identifiable {
    let author: String
    let name: String
    let description: String?
    let language: String?
    let languageColor: String?
    let stars: Int
    let currentPeriodStars: Int?

    var id: String { "\(author)/\(name)" }
    var fullName: String { "\(author)/\(name)" }

    enum CodingKeys: String, CodingKey {
        case author, name, description, language, languageColor, stars, currentPeriodStars
    }
}

struct TrendingEntry: TimelineEntry {
    let date: Date
    let repos: [TrendingRepo]
    let isPlaceholder: Bool

    static func placeholder() -> TrendingEntry {
        TrendingEntry(
            date: Date(),
            repos: [
                TrendingRepo(author: "apple", name: "swift", description: "The Swift Programming Language",
                             language: "C++", languageColor: "#f34b7d", stars: 68000, currentPeriodStars: 120),
                TrendingRepo(author: "Alamofire", name: "Alamofire", description: "Elegant HTTP Networking in Swift",
                             language: "Swift", languageColor: "#F05138", stars: 41000, currentPeriodStars: 86),
                TrendingRepo(author: "realm", name: "realm-swift", description: "Realm is a mobile database",
                             language: "Objective-C", languageColor: "#438eff", stars: 14000, currentPeriodStars: 42)
            ],
            isPlaceholder: true
        )
    }
}
