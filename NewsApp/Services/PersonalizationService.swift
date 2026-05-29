import Foundation
import NaturalLanguage
import SwiftData

protocol PersonalizationServiceProtocol {
    func score(articles: [Article], signals: [InterestSignal], obsidianContext: ObsidianContext?) -> [Article]
    func recordSignal(for article: Article, action: SwipeAction, context: ModelContext) async
}

// MARK: - Stub (replaced by full implementation in US3 phase)

final class PersonalizationServiceStub: PersonalizationServiceProtocol {
    func score(articles: [Article], signals: [InterestSignal], obsidianContext: ObsidianContext?) -> [Article] {
        articles
    }
    func recordSignal(for article: Article, action: SwipeAction, context: ModelContext) async {}
}

// MARK: - Full Implementation

final class PersonalizationService: PersonalizationServiceProtocol {

    func score(articles: [Article], signals: [InterestSignal], obsidianContext: ObsidianContext?) -> [Article] {
        let weightMap = buildWeightMap(signals: signals, obsidianContext: obsidianContext)
        guard !weightMap.isEmpty else { return articles }

        let scored = articles
        for article in scored {
            let text = article.title + " " + article.summary
            let keywords = extractKeywords(from: text)
            article.score = keywords.reduce(0.0) { acc, kw in acc + (weightMap[kw] ?? 0.0) }
        }
        return scored.sorted {
            $0.score != $1.score ? $0.score > $1.score : $0.fetchedAt > $1.fetchedAt
        }
    }

    func recordSignal(for article: Article, action: SwipeAction, context: ModelContext) async {
        let text = article.title + " " + article.summary
        let keywords = extractKeywords(from: text)
        let signalType: SignalType = action == .shared ? .shared : .notInterested
        for kw in keywords {
            let signal = InterestSignal(keyword: kw, signalType: signalType, sourceName: article.sourceName)
            context.insert(signal)
        }
        try? context.save()
    }

    // MARK: - Private

    private func buildWeightMap(signals: [InterestSignal], obsidianContext: ObsidianContext?) -> [String: Double] {
        var map: [String: Double] = [:]
        for signal in signals {
            map[signal.keyword, default: 0.0] += signal.weight
        }
        if let ctx = obsidianContext {
            for (kw, freq) in ctx.keywords {
                map[kw, default: 0.0] += Double(freq) * 1.0
            }
        }
        return map
    }

    func extractKeywords(from text: String) -> [String] {
        var keywords: [String] = []
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            guard let tag, tag == .noun || tag == .otherWord else { return true }
            let word = String(text[range]).lowercased()
            if word.count >= 2 { keywords.append(word) }
            return true
        }
        return keywords
    }
}
