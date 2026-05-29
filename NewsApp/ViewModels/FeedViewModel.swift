import Foundation
import SwiftData
import Combine

// MARK: - LastAction

enum LastAction {
    case swiped(article: Article, kind: SwipeAction)
    case skipped(article: Article)

    var article: Article {
        switch self {
        case .swiped(let a, _): a
        case .skipped(let a): a
        }
    }
}

// MARK: - FeedViewModel

@MainActor
final class FeedViewModel: ObservableObject {

    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var lastAction: LastAction? = nil
    @Published var skippedURLsInSession: Set<String> = []

    private let collector: NewsCollectorServiceProtocol
    private let personalization: PersonalizationServiceProtocol

    init(
        collector: NewsCollectorServiceProtocol = NewsCollectorService(),
        personalization: PersonalizationServiceProtocol = PersonalizationService()
    ) {
        self.collector = collector
        self.personalization = personalization
    }

    func reload(context: ModelContext, obsidianContext: ObsidianContext?) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await collector.fetchAll(context: context, obsidianContext: obsidianContext)
        } catch NewsCollectorError.allSourcesFailed(let names) {
            errorMessage = "取得失敗: \(names.joined(separator: ", "))"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func swipeRight(article: Article, context: ModelContext) async {
        lastAction = .swiped(article: article, kind: .shared)
        article.swipeAction = .shared
        try? context.save()
        await personalization.recordSignal(for: article, action: .shared, context: context)
    }

    func swipeLeft(article: Article, context: ModelContext) async {
        lastAction = .swiped(article: article, kind: .notInterested)
        article.swipeAction = .notInterested
        try? context.save()
        await personalization.recordSignal(for: article, action: .notInterested, context: context)
    }

    func skip(article: Article) {
        skippedURLsInSession.insert(article.url)
        lastAction = .skipped(article: article)
        // SwiftData 書き込みなし、PersonalizationService 呼び出しなし
    }

    func undo(context: ModelContext) {
        guard let action = lastAction else { return }
        switch action {
        case .swiped(let article, _):
            article.swipeAction = nil
            article.score = 0
            try? context.save()
        case .skipped(let article):
            skippedURLsInSession.remove(article.url)
        }
        lastAction = nil
    }
}
