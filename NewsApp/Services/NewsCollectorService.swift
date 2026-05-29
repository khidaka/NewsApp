import Foundation
import SwiftData

protocol NewsCollectorServiceProtocol {
    func fetchAll(context: ModelContext, obsidianContext: ObsidianContext?) async throws -> Int
}

final class NewsCollectorService: NewsCollectorServiceProtocol {

    private let parser: RSSParserServiceProtocol
    private let personalization: PersonalizationServiceProtocol
    private let maxArticles = 50

    init(
        parser: RSSParserServiceProtocol = RSSParserService(),
        personalization: PersonalizationServiceProtocol = PersonalizationService()
    ) {
        self.parser = parser
        self.personalization = personalization
    }

    func fetchAll(context: ModelContext, obsidianContext: ObsidianContext?) async throws -> Int {
        let sources = try fetchEnabledSources(context: context)
        guard !sources.isEmpty else { return 0 }

        let existingURLs: Set<String> = {
            let articles = (try? context.fetch(FetchDescriptor<Article>())) ?? []
            return Set(articles.map { $0.url })
        }()
        let sevenDaysAgo = Date.now.addingTimeInterval(-7 * 24 * 3600)

        var rawArticles: [RawArticle] = []
        var fetchErrors: [String] = []

        await withTaskGroup(of: Result<[RawArticle], Error>.self) { group in
            for source in sources {
                group.addTask {
                    do {
                        let articles = try await self.parser.parse(feedURL: source.feedURL, sourceName: source.name)
                        return .success(articles)
                    } catch {
                        return .failure(error)
                    }
                }
            }
            for source in sources {
                if case .failure = await group.next()! {
                    fetchErrors.append(source.name)
                }
            }
            for await result in group {
                if case .success(let articles) = result {
                    rawArticles.append(contentsOf: articles)
                }
            }
        }

        // Rebuild rawArticles properly
        rawArticles = []
        fetchErrors = []
        await withTaskGroup(of: (Result<[RawArticle], Error>, String).self) { group in
            for source in sources {
                group.addTask {
                    do {
                        let articles = try await self.parser.parse(feedURL: source.feedURL, sourceName: source.name)
                        return (.success(articles), source.name)
                    } catch {
                        return (.failure(error), source.name)
                    }
                }
            }
            for await (result, sourceName) in group {
                switch result {
                case .success(let articles): rawArticles.append(contentsOf: articles)
                case .failure: fetchErrors.append(sourceName)
                }
            }
        }

        if rawArticles.isEmpty && !fetchErrors.isEmpty {
            throw NewsCollectorError.allSourcesFailed(fetchErrors)
        }

        // Dedup by URL — skip already-seen URLs (swiped within 7 days or unswiped)
        let newRaw = rawArticles.filter { !existingURLs.contains($0.url) }

        // Convert to Article objects
        var newArticles = newRaw.map { raw in
            Article(
                url: raw.url,
                title: raw.title,
                summary: raw.summary,
                sourceName: raw.sourceName,
                sourceURL: raw.sourceURL,
                fetchedAt: raw.publishedAt ?? .now
            )
        }

        // Load signals for scoring
        let signals = (try? context.fetch(FetchDescriptor<InterestSignal>(
            predicate: #Predicate { $0.recordedAt > sevenDaysAgo }
        ))) ?? []

        // Score and take top maxArticles
        newArticles = personalization.score(articles: newArticles, signals: signals, obsidianContext: obsidianContext)
        let topArticles = Array(newArticles.prefix(maxArticles))

        // Persist
        for article in topArticles {
            context.insert(article)
        }
        try? context.save()

        // Cleanup expired records
        cleanupExpired(context: context, before: sevenDaysAgo)

        return topArticles.count
    }

    // MARK: - Private

    private func fetchEnabledSources(context: ModelContext) throws -> [NewsSource] {
        let descriptor = FetchDescriptor<NewsSource>(
            predicate: #Predicate { $0.isEnabled }
        )
        return try context.fetch(descriptor)
    }

    private func cleanupExpired(context: ModelContext, before date: Date) {
        let expiredArticles = (try? context.fetch(FetchDescriptor<Article>(
            predicate: #Predicate { $0.swipeActionRaw != nil && $0.fetchedAt < date }
        ))) ?? []
        expiredArticles.forEach { context.delete($0) }

        let expiredSignals = (try? context.fetch(FetchDescriptor<InterestSignal>(
            predicate: #Predicate { $0.recordedAt < date }
        ))) ?? []
        expiredSignals.forEach { context.delete($0) }

        try? context.save()
    }
}

enum NewsCollectorError: LocalizedError {
    case allSourcesFailed([String])

    var errorDescription: String? {
        switch self {
        case .allSourcesFailed(let names):
            return "すべてのニュースソースの取得に失敗しました: \(names.joined(separator: ", "))"
        }
    }
}
