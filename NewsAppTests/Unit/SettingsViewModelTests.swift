import XCTest
import SwiftData
@testable import NewsApp

@MainActor
final class SettingsViewModelTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!
    private var viewModel: SettingsViewModel!

    override func setUpWithError() throws {
        container = try ModelContainer(
            for: Article.self, NewsSource.self, InterestSignal.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
        viewModel = SettingsViewModel()
    }

    func testAddSource_validURL_succeeds() throws {
        try viewModel.addSource(name: "NHK", feedURL: "https://www3.nhk.or.jp/rss/news/cat0.xml", context: context)
        let sources = try context.fetch(FetchDescriptor<NewsSource>())
        XCTAssertEqual(sources.count, 1)
        XCTAssertEqual(sources.first?.name, "NHK")
    }

    func testAddSource_invalidURL_throws() {
        XCTAssertThrowsError(try viewModel.addSource(name: "", feedURL: "not-a-url", context: context)) { error in
            XCTAssertEqual(error as? SourceError, SourceError.invalidURL)
        }
    }

    func testAddSource_emptyName_usesURL() throws {
        let url = "https://example.com/feed.xml"
        try viewModel.addSource(name: "", feedURL: url, context: context)
        let sources = try context.fetch(FetchDescriptor<NewsSource>())
        XCTAssertEqual(sources.first?.name, url)
    }

    func testAddSourceStillWorksWithCustomURL() throws {
        let customURL = "https://custom-blog.example.com/feed.rss"
        XCTAssertFalse(SuggestedSources.all.map(\.feedURL).contains(customURL), "Test URL must not be in suggested catalog")
        try viewModel.addSource(name: "Custom Blog", feedURL: customURL, context: context)
        let sources = try context.fetch(FetchDescriptor<NewsSource>())
        XCTAssertEqual(sources.count, 1)
        XCTAssertEqual(sources.first?.feedURL, customURL)
    }

    func testDeleteSource_removesFromStore() throws {
        try viewModel.addSource(name: "Test", feedURL: "https://example.com/feed", context: context)
        let sources = try context.fetch(FetchDescriptor<NewsSource>())
        let source = try XCTUnwrap(sources.first)
        viewModel.deleteSource(source, context: context)
        let remaining = try context.fetch(FetchDescriptor<NewsSource>())
        XCTAssertTrue(remaining.isEmpty)
    }
}

extension SourceError: Equatable {
    public static func == (lhs: SourceError, rhs: SourceError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL): true
        }
    }
}
