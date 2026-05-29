import XCTest
import SwiftData
@testable import NewsApp

final class NewsCollectorIntegrationTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        container = try ModelContainer(
            for: Article.self, NewsSource.self, InterestSignal.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
    }

    // MARK: - URL deduplication

    func testFetchAll_deduplicatesURLs() async throws {
        // 同じ URL の記事が複数ソースから取得された場合に重複除去される
        let existing = Article(url: "https://example.com/news/1", title: "既存", summary: "既存", sourceName: "test", sourceURL: "")
        context.insert(existing)
        try context.save()

        let mockParser = MockRSSParser(articles: [
            RawArticle(title: "重複", summary: "重複", url: "https://example.com/news/1", publishedAt: nil, sourceName: "src", sourceURL: ""),
            RawArticle(title: "新規", summary: "新規", url: "https://example.com/news/2", publishedAt: nil, sourceName: "src", sourceURL: "")
        ])
        let source = NewsSource(name: "test", feedURL: "https://example.com/feed")
        context.insert(source)
        try context.save()

        let service = NewsCollectorService(parser: mockParser, personalization: PersonalizationServiceStub())
        let count = try await service.fetchAll(context: context, obsidianContext: nil)

        XCTAssertEqual(count, 1, "重複 URL は除去されて新規1件のみ追加")
    }

    func testFetchAll_limitsTo50Articles() async throws {
        let manyArticles = (1...60).map { i in
            RawArticle(title: "記事\(i)", summary: "概要\(i)", url: "https://example.com/\(i)", publishedAt: nil, sourceName: "src", sourceURL: "")
        }
        let mockParser = MockRSSParser(articles: manyArticles)
        let source = NewsSource(name: "test", feedURL: "https://example.com/feed")
        context.insert(source)
        try context.save()

        let service = NewsCollectorService(parser: mockParser, personalization: PersonalizationServiceStub())
        let count = try await service.fetchAll(context: context, obsidianContext: nil)

        XCTAssertLessThanOrEqual(count, 50, "フェッチ結果は最大50件")
    }

    func testFetchAll_continuesOnPartialFailure() async throws {
        let mockParser = MockRSSParserWithFailure()
        let source1 = NewsSource(name: "success", feedURL: "https://success.com/feed")
        let source2 = NewsSource(name: "fail", feedURL: "https://fail.com/feed")
        context.insert(source1)
        context.insert(source2)
        try context.save()

        let service = NewsCollectorService(parser: mockParser, personalization: PersonalizationServiceStub())
        let count = try await service.fetchAll(context: context, obsidianContext: nil)
        XCTAssertGreaterThan(count, 0, "一部失敗でも成功ソースの記事は取得される")
    }
}

// MARK: - Mocks

final class MockRSSParser: RSSParserServiceProtocol {
    let articles: [RawArticle]
    init(articles: [RawArticle]) { self.articles = articles }
    func parse(feedURL: String, sourceName: String) async throws -> [RawArticle] { articles }
}

final class MockRSSParserWithFailure: RSSParserServiceProtocol {
    func parse(feedURL: String, sourceName: String) async throws -> [RawArticle] {
        if feedURL.contains("fail") { throw URLError(.notConnectedToInternet) }
        return [RawArticle(title: "OK", summary: "OK", url: "https://success.com/1", publishedAt: nil, sourceName: sourceName, sourceURL: feedURL)]
    }
}
