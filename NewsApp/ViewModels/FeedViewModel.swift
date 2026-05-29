import Foundation
import SwiftData
import Combine

@MainActor
final class FeedViewModel: ObservableObject {

    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var lastSwipedArticle: Article? = nil

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
        lastSwipedArticle = article
        article.swipeAction = .shared
        try? context.save()
        await personalization.recordSignal(for: article, action: .shared, context: context)
    }

    func swipeLeft(article: Article, context: ModelContext) async {
        lastSwipedArticle = article
        article.swipeAction = .notInterested
        try? context.save()
        await personalization.recordSignal(for: article, action: .notInterested, context: context)
    }

    func undo(context: ModelContext) {
        guard let article = lastSwipedArticle else { return }
        article.swipeAction = nil
        article.score = 0
        try? context.save()
        lastSwipedArticle = nil
    }
}
