import XCTest
@testable import NewsApp

final class SuggestedSourcesTests: XCTestCase {

    // MARK: - Catalog

    func testCatalogHasMinimumSources() {
        XCTAssertGreaterThanOrEqual(SuggestedSources.all.count, 5)
    }

    func testCatalogURLsAreUnique() {
        let urls = SuggestedSources.all.map(\.feedURL)
        XCTAssertEqual(urls.count, Set(urls).count)
    }

    func testEachSourceHasNonEmptyNameAndURL() {
        for source in SuggestedSources.all {
            XCTAssertFalse(source.name.isEmpty, "Name must not be empty")
            XCTAssertFalse(source.feedURL.isEmpty, "feedURL must not be empty")
        }
    }

    // MARK: - filtered(excluding:)

    func testFilteredSuggestionsReturnsAllWhenNoneAdded() {
        let result = SuggestedSources.filtered(excluding: [])
        XCTAssertEqual(result.count, SuggestedSources.all.count)
    }

    func testFilteredSuggestionsExcludesAddedURLs() {
        guard let first = SuggestedSources.all.first else {
            XCTFail("Catalog must not be empty")
            return
        }
        let result = SuggestedSources.filtered(excluding: [first.feedURL])
        XCTAssertEqual(result.count, SuggestedSources.all.count - 1)
        XCTAssertFalse(result.contains(first))
    }

    func testFilteredSuggestionsIsEmptyWhenAllAdded() {
        let allURLs = Set(SuggestedSources.all.map(\.feedURL))
        let result = SuggestedSources.filtered(excluding: allURLs)
        XCTAssertTrue(result.isEmpty)
    }

    func testFilteredSuggestionsIgnoresUnrelatedURLs() {
        let unrelated: Set<String> = ["https://example.com/unknown.rss"]
        let result = SuggestedSources.filtered(excluding: unrelated)
        XCTAssertEqual(result.count, SuggestedSources.all.count)
    }
}
