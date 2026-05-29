import XCTest
import SwiftData
@testable import NewsApp

@MainActor
final class FeedViewModelSkipTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!
    private var mockPersonalization: MockPersonalizationService!
    private var viewModel: FeedViewModel!

    override func setUpWithError() throws {
        container = try ModelContainer(
            for: Article.self, NewsSource.self, InterestSignal.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
        mockPersonalization = MockPersonalizationService()
        viewModel = FeedViewModel(
            collector: MockNewsCollector(),
            personalization: mockPersonalization
        )
    }

    // MARK: - skip() tests

    func testSkip_doesNotSetSwipeAction() {
        let article = makeArticle(url: "https://example.com/1")
        viewModel.skip(article: article)
        XCTAssertNil(article.swipeAction, "スキップは swipeAction を変更しない")
    }

    func testSkip_addsURLToSession() {
        let article = makeArticle(url: "https://example.com/1")
        viewModel.skip(article: article)
        XCTAssertTrue(viewModel.skippedURLsInSession.contains(article.url), "スキップ後はセッション除外セットに URL が追加される")
    }

    func testSkip_doesNotCallPersonalizationService() {
        let article = makeArticle(url: "https://example.com/1")
        viewModel.skip(article: article)
        XCTAssertFalse(mockPersonalization.recordSignalCalled, "スキップは PersonalizationService を呼ばない")
    }

    func testSkip_setsLastActionToSkipped() {
        let article = makeArticle(url: "https://example.com/1")
        viewModel.skip(article: article)
        guard case .skipped(let a) = viewModel.lastAction else {
            return XCTFail("lastAction は .skipped になるべき")
        }
        XCTAssertEqual(a.url, article.url)
    }

    // MARK: - undo() tests

    func testUndo_afterSkip_removesFromSession() {
        let article = makeArticle(url: "https://example.com/1")
        viewModel.skip(article: article)
        XCTAssertTrue(viewModel.skippedURLsInSession.contains(article.url))

        viewModel.undo(context: context)
        XCTAssertFalse(viewModel.skippedURLsInSession.contains(article.url), "Undo でセッション除外が解除される")
    }

    func testUndo_afterSkip_clearsLastAction() {
        let article = makeArticle(url: "https://example.com/1")
        viewModel.skip(article: article)
        viewModel.undo(context: context)
        XCTAssertNil(viewModel.lastAction, "Undo 後は lastAction が nil になる")
    }

    func testUndo_afterSkip_doesNotModifySwipeAction() {
        let article = makeArticle(url: "https://example.com/1")
        viewModel.skip(article: article)
        viewModel.undo(context: context)
        XCTAssertNil(article.swipeAction, "Undo 後も swipeAction は nil のまま")
    }

    // MARK: - swipe tests (lastAction migration)

    func testSwipeRight_setsLastActionToSwiped() async {
        let article = makeArticle(url: "https://example.com/1")
        context.insert(article)
        await viewModel.swipeRight(article: article, context: context)
        guard case .swiped(let a, let kind) = viewModel.lastAction else {
            return XCTFail("lastAction は .swiped になるべき")
        }
        XCTAssertEqual(a.url, article.url)
        XCTAssertEqual(kind, .shared)
    }

    // MARK: - Helpers

    private func makeArticle(url: String) -> Article {
        Article(url: url, title: "テスト", summary: "概要", sourceName: "src", sourceURL: "")
    }
}

// MARK: - Mocks

final class MockPersonalizationService: PersonalizationServiceProtocol {
    var recordSignalCalled = false
    func score(articles: [Article], signals: [InterestSignal], obsidianContext: ObsidianContext?) -> [Article] { articles }
    @MainActor func recordSignal(for article: Article, action: SwipeAction, context: ModelContext) async {
        recordSignalCalled = true
    }
}

final class MockNewsCollector: NewsCollectorServiceProtocol {
    func fetchAll(context: ModelContext, obsidianContext: ObsidianContext?) async throws -> Int { 0 }
}
