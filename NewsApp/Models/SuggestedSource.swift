import Foundation

struct SuggestedSource: Hashable {
    let name: String
    let feedURL: String
}

enum SuggestedSources {
    static let all: [SuggestedSource] = [
        SuggestedSource(name: "NHK ニュース",        feedURL: "https://www.nhk.or.jp/rss/news/cat0.xml"),
        SuggestedSource(name: "朝日新聞 デジタル",   feedURL: "https://www.asahi.com/rss/asahi/newsheadlines.rdf"),
        SuggestedSource(name: "毎日新聞",             feedURL: "https://mainichi.jp/rss/etc/mainichi-flash.rss"),
        SuggestedSource(name: "Reuters Japan",        feedURL: "https://feeds.reuters.com/reuters/JPTopNews"),
        SuggestedSource(name: "Gigazine",             feedURL: "https://gigazine.net/news/rss_2.0/"),
        SuggestedSource(name: "TechCrunch Japan",     feedURL: "https://jp.techcrunch.com/feed/"),
        SuggestedSource(name: "Hacker News",          feedURL: "https://news.ycombinator.com/rss"),
    ]

    static func filtered(excluding addedURLs: Set<String>) -> [SuggestedSource] {
        all.filter { !addedURLs.contains($0.feedURL) }
    }
}
