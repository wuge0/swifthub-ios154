//
//  TrendingService.swift
//  SwiftHubWidget
//
//  只依赖公开接口，不需要登录态，因此在 Widget 中可直接使用
//

import Foundation

enum TrendingService {

    /// 与主 App 的 Configs.Network.trendingGithubBaseUrl 保持一致
    static let endpoint = URL(string: "https://api.gitterapp.com/repositories?since=daily")!

    static func fetch(limit: Int = 10, completion: @escaping ([TrendingRepo]) -> Void) {
        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 15
        request.setValue("SwiftHubWidget/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let repos = try? JSONDecoder().decode([TrendingRepo].self, from: data) else {
                completion([])
                return
            }
            completion(Array(repos.prefix(limit)))
        }.resume()
    }
}
