import Foundation

struct RawArticle {
    let title: String
    let summary: String
    let url: String
    let publishedAt: Date?
    let sourceName: String
    let sourceURL: String
}

protocol RSSParserServiceProtocol {
    func parse(feedURL: String, sourceName: String) async throws -> [RawArticle]
}

// MARK: - Implementation

final class RSSParserService: RSSParserServiceProtocol {
    func parse(feedURL: String, sourceName: String) async throws -> [RawArticle] {
        guard let url = URL(string: feedURL) else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try FeedParser(data: data, feedURL: feedURL, sourceName: sourceName).parse()
    }
}

// MARK: - FeedKit wrapper

import FeedKit

private struct FeedParser {
    let data: Data
    let feedURL: String
    let sourceName: String

    func parse() throws -> [RawArticle] {
        let parser = FeedKit.FeedParser(data: data)
        let result = parser.parse()
        switch result {
        case .success(let feed):
            return articles(from: feed)
        case .failure(let error):
            throw error
        }
    }

    private func articles(from feed: Feed) -> [RawArticle] {
        switch feed {
        case .rss(let rss):
            return (rss.items ?? []).compactMap { item in
                guard let link = item.link, !link.isEmpty else { return nil }
                let title = item.title ?? link
                let summary = item.description?.strippingHTML() ?? title
                return RawArticle(
                    title: title,
                    summary: String(summary.prefix(300)),
                    url: link,
                    publishedAt: item.pubDate,
                    sourceName: sourceName,
                    sourceURL: feedURL
                )
            }
        case .atom(let atom):
            return (atom.entries ?? []).compactMap { entry -> RawArticle? in
                guard let link = entry.links?.first?.attributes?.href, !link.isEmpty else { return nil }
                let title = entry.title ?? link
                let summary = entry.summary?.value?.strippingHTML() ?? title
                return RawArticle(
                    title: title,
                    summary: String(summary.prefix(300)),
                    url: link,
                    publishedAt: entry.published,
                    sourceName: sourceName,
                    sourceURL: feedURL
                )
            }
        case .json(let json):
            return (json.items ?? []).compactMap { item in
                guard let link = item.url, !link.isEmpty else { return nil }
                let title = item.title ?? link
                let summary = item.summary ?? item.contentText ?? title
                return RawArticle(
                    title: title,
                    summary: String(summary.prefix(300)),
                    url: link,
                    publishedAt: item.datePublished,
                    sourceName: sourceName,
                    sourceURL: feedURL
                )
            }
        }
    }
}

private extension String {
    func strippingHTML() -> String {
        guard let data = self.data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil)
        return attributed?.string ?? self
    }
}
