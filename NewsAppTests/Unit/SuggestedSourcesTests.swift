import XCTest
import SwiftData
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

    func testEachSourceHasKeywords() {
        for source in SuggestedSources.all {
            XCTAssertFalse(source.keywords.isEmpty, "\(source.name) must have keywords")
        }
    }

    // MARK: - filtered(excluding:)

    func testFilteredSuggestionsReturnsAllWhenNoneAdded() {
        let result = SuggestedSources.filtered(excluding: [])
        XCTAssertEqual(result.count, SuggestedSources.all.count)
    }

    func testFilteredSuggestionsExcludesAddedURLs() {
        guard let first = SuggestedSources.all.first else {
            XCTFail("Catalog must not be empty"); return
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

    // MARK: - ranked(excluding:signals:) — T002 + T006

    func testRanked_noSignals_returnsDefaultOrder() {
        let result = SuggestedSources.ranked(excluding: [], signals: [])
        let expected = SuggestedSources.all.map(\.feedURL)
        XCTAssertEqual(result.map(\.feedURL), expected, "シグナルなし（新規ユーザー）は定義順で返る")
    }

    func testRanked_positiveSignal_promotesMatchingSource() {
        // TechCrunch は "tech" キーワードを持つ → "tech" への共有シグナルで上位に来るべき
        let techSignal = InterestSignal(keyword: "tech", signalType: .shared, sourceName: "any")
        let result = SuggestedSources.ranked(excluding: [], signals: [techSignal])
        let techCrunchIndex = result.firstIndex { $0.name == "TechCrunch Japan" }
        let hackerNewsIndex = result.firstIndex { $0.name == "Hacker News" }
        let nhkIndex = result.firstIndex { $0.name == "NHK ニュース" }
        XCTAssertNotNil(techCrunchIndex)
        XCTAssertNotNil(hackerNewsIndex)
        XCTAssertNotNil(nhkIndex)
        XCTAssertLessThan(techCrunchIndex!, nhkIndex!, "TechCrunch は NHK より上位になるべき")
    }

    func testRanked_negativeSignal_demotesMatchingSource() {
        // "tech" への興味なしシグナルが強い場合、tech 系ソースは下位に来るべき
        let negSignals = (0..<5).map { _ in InterestSignal(keyword: "tech", signalType: .notInterested, sourceName: "any") }
        let result = SuggestedSources.ranked(excluding: [], signals: negSignals)
        let techCrunchIndex = result.firstIndex { $0.name == "TechCrunch Japan" }
        let nhkIndex = result.firstIndex { $0.name == "NHK ニュース" }
        XCTAssertNotNil(techCrunchIndex)
        XCTAssertNotNil(nhkIndex)
        XCTAssertLessThan(nhkIndex!, techCrunchIndex!, "興味なし後 NHK は TechCrunch より上位になるべき")
    }

    func testRanked_tieBreak_preservesDefinitionOrder() {
        // 全ソースに無関係なシグナル → 全件0点 → 定義順を維持
        let unrelatedSignal = InterestSignal(keyword: "zzz_unrelated_xyz", signalType: .shared, sourceName: "any")
        let result = SuggestedSources.ranked(excluding: [], signals: [unrelatedSignal])
        let expected = SuggestedSources.all.map(\.feedURL)
        XCTAssertEqual(result.map(\.feedURL), expected, "同点時は定義順（FR-009）")
    }

    func testRanked_excludesAddedSources() {
        guard let first = SuggestedSources.all.first else { XCTFail(); return }
        let result = SuggestedSources.ranked(excluding: [first.feedURL], signals: [])
        XCTAssertFalse(result.contains(first), "追加済みソースは ranked 結果に含まれない（FR-005）")
        XCTAssertEqual(result.count, SuggestedSources.all.count - 1)
    }

    func testRanked_multiplePositiveSignals_accumulateScore() {
        // "tech" 複数回共有 → TechCrunch / Hacker News が NHK より上位
        let signals = (0..<3).map { _ in InterestSignal(keyword: "tech", signalType: .shared, sourceName: "any") }
        let result = SuggestedSources.ranked(excluding: [], signals: signals)
        let techCrunchIndex = result.firstIndex { $0.name == "TechCrunch Japan" }!
        let nhkIndex = result.firstIndex { $0.name == "NHK ニュース" }!
        XCTAssertLessThan(techCrunchIndex, nhkIndex, "複数シグナルの蓄積で TechCrunch が上位")
    }
}
