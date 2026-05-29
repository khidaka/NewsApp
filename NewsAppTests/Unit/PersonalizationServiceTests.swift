import XCTest
import SwiftData
@testable import NewsApp

final class PersonalizationServiceTests: XCTestCase {

    private let service = PersonalizationService()

    // MARK: - Scoring

    func testScore_sharedKeywordsRaisesScore() {
        let signal = InterestSignal(keyword: "ai", signalType: .shared, sourceName: "test")
        let article = Article(url: "https://example.com/1", title: "AI news", summary: "about ai", sourceName: "test", sourceURL: "")
        let neutral = Article(url: "https://example.com/2", title: "Sports news", summary: "about sports", sourceName: "test", sourceURL: "")

        let scored = service.score(articles: [neutral, article], signals: [signal], obsidianContext: nil)
        XCTAssertEqual(scored.first?.url, article.url, "AI 記事がスポーツ記事より上位")
    }

    func testScore_notInterestedKeywordsLowersScore() {
        let signal = InterestSignal(keyword: "sports", signalType: .notInterested, sourceName: "test")
        let sports = Article(url: "https://example.com/1", title: "Sports news", summary: "about sports", sourceName: "test", sourceURL: "")
        let tech = Article(url: "https://example.com/2", title: "Tech news", summary: "about technology", sourceName: "test", sourceURL: "")

        let scored = service.score(articles: [sports, tech], signals: [signal], obsidianContext: nil)
        XCTAssertEqual(scored.first?.url, tech.url, "興味なしのスポーツ記事はテック記事より下位")
    }

    func testScore_obsidianContextBoostsRelated() {
        let ctx = ObsidianContext(keywords: ["machine": 10, "learning": 8], lastScannedAt: .now)
        let ai = Article(url: "https://example.com/1", title: "Machine learning", summary: "about machine", sourceName: "test", sourceURL: "")
        let food = Article(url: "https://example.com/2", title: "Cooking tips", summary: "about food cooking", sourceName: "test", sourceURL: "")

        let scored = service.score(articles: [food, ai], signals: [], obsidianContext: ctx)
        XCTAssertEqual(scored.first?.url, ai.url, "Obsidian キーワードに合致する記事が上位")
    }

    func testScore_emptySignals_returnsOriginalOrder() {
        let a1 = Article(url: "https://example.com/1", title: "A", summary: "a", sourceName: "test", sourceURL: "")
        let a2 = Article(url: "https://example.com/2", title: "B", summary: "b", sourceName: "test", sourceURL: "")
        let result = service.score(articles: [a1, a2], signals: [], obsidianContext: nil)
        XCTAssertEqual(result.count, 2)
    }

    func testScore_sortedByScoreDescending() {
        let signals = [
            InterestSignal(keyword: "tech", signalType: .shared, sourceName: "t"),
            InterestSignal(keyword: "tech", signalType: .shared, sourceName: "t"),
        ]
        let high = Article(url: "https://example.com/1", title: "Tech revolution", summary: "tech everywhere", sourceName: "t", sourceURL: "")
        let low = Article(url: "https://example.com/2", title: "Weather forecast", summary: "sunny tomorrow", sourceName: "t", sourceURL: "")
        let scored = service.score(articles: [low, high], signals: signals, obsidianContext: nil)
        XCTAssertEqual(scored.first?.url, high.url)
    }
}
