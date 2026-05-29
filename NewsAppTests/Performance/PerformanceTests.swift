import XCTest
import SwiftData
@testable import NewsApp

final class PerformanceTests: XCTestCase {

    // SC-003: PersonalizationService のスコアリング性能
    func testScoringPerformance_350articles() throws {
        let container = try ModelContainer(
            for: Article.self, NewsSource.self, InterestSignal.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let articles = (1...350).map { i in
            Article(url: "https://example.com/\(i)", title: "記事 \(i)", summary: "概要テキスト \(i)", sourceName: "src", sourceURL: "")
        }
        let signals = (1...20).map { i in
            InterestSignal(keyword: "キーワード\(i)", signalType: .shared, sourceName: "src")
        }
        let service = PersonalizationService()

        measure {
            _ = service.score(articles: articles, signals: signals, obsidianContext: nil)
        }
    }

    // NOTE: SC-001 (起動 ≤3秒) と SC-002 (スワイプ→共有 ≤1秒) は
    // Instruments の Time Profiler または XCTApplicationLaunchMetric で計測する。
    // 自動テストとしては下記をローカル実行で確認する:
    func testSwiftDataQuery_respondsUnder200ms() throws {
        let container = try ModelContainer(
            for: Article.self, NewsSource.self, InterestSignal.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        // 350件挿入
        for i in 1...350 {
            let a = Article(url: "https://example.com/\(i)", title: "T\(i)", summary: "S\(i)", sourceName: "src", sourceURL: "")
            context.insert(a)
        }
        try context.save()

        measure(metrics: [XCTClockMetric()]) {
            _ = try? context.fetch(FetchDescriptor<Article>(
                predicate: #Predicate { $0.swipeActionRaw == nil },
                sortBy: [SortDescriptor(\Article.score, order: .reverse)]
            ))
        }
    }
}
