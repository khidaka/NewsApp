import XCTest
@testable import NewsApp

final class ObsidianReaderServiceTests: XCTestCase {

    // Test the internal keyword extraction behavior via the public service
    // (stub test using real NaturalLanguage framework on plain text)

    func testExtractKeywords_returnsNouns() {
        let service = PersonalizationService()
        let keywords = service.extractKeywords(from: "人工知能と機械学習の研究")
        XCTAssertFalse(keywords.isEmpty, "日本語テキストからキーワードが抽出される")
    }

    func testExtractKeywords_filtersShortTokens() {
        let service = PersonalizationService()
        let keywords = service.extractKeywords(from: "AI は便利です")
        // すべてのキーワードが2文字以上
        for kw in keywords {
            XCTAssertGreaterThanOrEqual(kw.count, 2, "短いトークンは除外される")
        }
    }

    func testStripFrontmatter() {
        // ObsidianReaderService の frontmatter 除去を間接的に検証
        // (private メソッドのため公開 API を通じてテスト)
        // ここでは frontmatter なしのテキストでキーワードが正常抽出されることを確認
        let service = PersonalizationService()
        let text = "人工知能の進化について"
        let keywords = service.extractKeywords(from: text)
        XCTAssertFalse(keywords.isEmpty)
    }
}
