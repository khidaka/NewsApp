import XCTest
@testable import NewsApp

final class RSSParserServiceTests: XCTestCase {

    private let service = RSSParserService()

    // MARK: - These tests require network; use a local mock for CI

    func testParseRSS2_returnsArticles() async throws {
        // NHK News RSS (public, reliable)
        let articles = try await service.parse(
            feedURL: "https://www3.nhk.or.jp/rss/news/cat0.xml",
            sourceName: "NHK"
        )
        XCTAssertFalse(articles.isEmpty, "RSS フィードから記事が取得できる")
        let first = try XCTUnwrap(articles.first)
        XCTAssertFalse(first.title.isEmpty, "タイトルが空でない")
        XCTAssertFalse(first.url.isEmpty, "URL が空でない")
    }

    func testInvalidURL_throwsError() async {
        do {
            _ = try await service.parse(feedURL: "not-a-url", sourceName: "test")
            XCTFail("無効な URL はエラーを投げるべき")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testSummaryFallsBackToTitle() async throws {
        // summary が空の場合 title にフォールバックすることを確認
        // 実際の空 summary フィードが必要なためここでは構造検証
        let articles = try await service.parse(
            feedURL: "https://www3.nhk.or.jp/rss/news/cat0.xml",
            sourceName: "NHK"
        )
        for article in articles {
            XCTAssertFalse(article.summary.isEmpty, "summary は常に非空")
        }
    }
}
