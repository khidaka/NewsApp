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
        context.insert(article)
        viewModel.skip(article: article, context: context)
        XCTAssertNil(article.swipeAction, "スキップは swipeAction を変更しない")
    }

    func testSkip_setsIsSkippedTrue() {
        let article = makeArticle(url: "https://example.com/persist")
        context.insert(article)
        viewModel.skip(article: article, context: context)
        XCTAssertTrue(article.isSkipped, "スキップ後は isSkipped が true になる")
    }

    func testSkip_savesToContext() throws {
        let article = makeArticle(url: "https://example.com/persist2")
        context.insert(article)
        viewModel.skip(article: article, context: context)

        let descriptor = FetchDescriptor<Article>(
            predicate: #Predicate { $0.url == "https://example.com/persist2" }
        )
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.first?.isSkipped, true, "SwiftData に isSkipped=true が保存されている")
    }

    func testSkip_doesNotCallPersonalizationService() {
        let article = makeArticle(url: "https://example.com/1")
        context.insert(article)
        viewModel.skip(article: article, context: context)
        XCTAssertFalse(mockPersonalization.recordSignalCalled, "スキップは PersonalizationService を呼ばない")
    }

    func testSkip_setsLastActionToSkipped() {
        let article = makeArticle(url: "https://example.com/1")
        context.insert(article)
        viewModel.skip(article: article, context: context)
        guard case .skipped(let a) = viewModel.lastAction else {
            return XCTFail("lastAction は .skipped になるべき")
        }
        XCTAssertEqual(a.url, article.url)
    }

    // MARK: - undo() tests

    func testUndo_afterSkip_setsIsSkippedFalse() {
        let article = makeArticle(url: "https://example.com/1")
        context.insert(article)
        viewModel.skip(article: article, context: context)
        XCTAssertTrue(article.isSkipped)

        viewModel.undo(context: context)
        XCTAssertFalse(article.isSkipped, "Undo で isSkipped が false に戻る")
    }

    func testUndo_afterSkip_savesToContext() throws {
        let article = makeArticle(url: "https://example.com/undo-persist")
        context.insert(article)
        viewModel.skip(article: article, context: context)
        viewModel.undo(context: context)

        let descriptor = FetchDescriptor<Article>(
            predicate: #Predicate { $0.url == "https://example.com/undo-persist" }
        )
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.first?.isSkipped, false, "Undo 後は SwiftData に isSkipped=false が保存されている")
    }

    func testUndo_afterSkip_clearsLastAction() {
        let article = makeArticle(url: "https://example.com/1")
        context.insert(article)
        viewModel.skip(article: article, context: context)
        viewModel.undo(context: context)
        XCTAssertNil(viewModel.lastAction, "Undo 後は lastAction が nil になる")
    }

    func testUndo_afterSkip_doesNotModifySwipeAction() {
        let article = makeArticle(url: "https://example.com/1")
        context.insert(article)
        viewModel.skip(article: article, context: context)
        viewModel.undo(context: context)
        XCTAssertNil(article.swipeAction, "Undo 後も swipeAction は nil のまま")
    }

    // MARK: - swipe tests

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
