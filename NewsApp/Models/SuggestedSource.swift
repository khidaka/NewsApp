import Foundation

struct SuggestedSource: Hashable {
    let name: String
    let feedURL: String
    let keywords: [String]

    func hash(into hasher: inout Hasher) {
        hasher.combine(feedURL)
    }

    static func == (lhs: SuggestedSource, rhs: SuggestedSource) -> Bool {
        lhs.feedURL == rhs.feedURL
    }
}

enum SuggestedSources {
    static let all: [SuggestedSource] = [
        SuggestedSource(
            name: "NHK ニュース",
            feedURL: "https://www.nhk.or.jp/rss/news/cat0.xml",
            keywords: ["ニュース", "速報", "政治", "社会", "国内"]
        ),
        SuggestedSource(
            name: "朝日新聞 デジタル",
            feedURL: "https://www.asahi.com/rss/asahi/newsheadlines.rdf",
            keywords: ["ニュース", "政治", "社会", "経済", "国際"]
        ),
        SuggestedSource(
            name: "毎日新聞",
            feedURL: "https://mainichi.jp/rss/etc/mainichi-flash.rss",
            keywords: ["ニュース", "政治", "社会", "事件"]
        ),
        SuggestedSource(
            name: "Reuters Japan",
            feedURL: "https://feeds.reuters.com/reuters/JPTopNews",
            keywords: ["経済", "国際", "ビジネス", "金融", "マーケット"]
        ),
        SuggestedSource(
            name: "Gigazine",
            feedURL: "https://gigazine.net/news/rss_2.0/",
            keywords: ["テクノロジー", "ガジェット", "科学", "レビュー"]
        ),
        SuggestedSource(
            name: "TechCrunch Japan",
            feedURL: "https://jp.techcrunch.com/feed/",
            keywords: ["tech", "テクノロジー", "スタートアップ", "アプリ", "ai"]
        ),
        SuggestedSource(
            name: "Hacker News",
            feedURL: "https://news.ycombinator.com/rss",
            keywords: ["tech", "プログラミング", "スタートアップ", "ソフトウェア"]
        ),
    ]

    static func filtered(excluding addedURLs: Set<String>) -> [SuggestedSource] {
        all.filter { !addedURLs.contains($0.feedURL) }
    }

    static func ranked(excluding addedURLs: Set<String>, signals: [InterestSignal]) -> [SuggestedSource] {
        let candidates = all.enumerated().filter { !addedURLs.contains($0.element.feedURL) }
        guard !signals.isEmpty else {
            return candidates.map(\.element)
        }
        var weightMap: [String: Double] = [:]
        for signal in signals {
            weightMap[signal.keyword, default: 0.0] += signal.weight
        }
        return candidates
            .sorted { lhs, rhs in
                let scoreL = lhs.element.keywords.reduce(0.0) { $0 + (weightMap[$1] ?? 0.0) }
                let scoreR = rhs.element.keywords.reduce(0.0) { $0 + (weightMap[$1] ?? 0.0) }
                if scoreL != scoreR { return scoreL > scoreR }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }
}
