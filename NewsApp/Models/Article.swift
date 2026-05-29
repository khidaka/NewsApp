import Foundation
import SwiftData

enum SwipeAction: String, Codable {
    case shared
    case notInterested
}

@Model
final class Article {
    @Attribute(.unique) var url: String
    var id: UUID
    var title: String
    var summary: String
    var sourceName: String
    var sourceURL: String
    var fetchedAt: Date
    var swipeActionRaw: String?
    var score: Double

    var swipeAction: SwipeAction? {
        get { swipeActionRaw.flatMap { SwipeAction(rawValue: $0) } }
        set { swipeActionRaw = newValue?.rawValue }
    }

    init(
        url: String,
        title: String,
        summary: String,
        sourceName: String,
        sourceURL: String,
        fetchedAt: Date = .now,
        swipeAction: SwipeAction? = nil,
        score: Double = 0.0
    ) {
        self.id = UUID()
        self.url = url
        self.title = title
        self.summary = summary
        self.sourceName = sourceName
        self.sourceURL = sourceURL
        self.fetchedAt = fetchedAt
        self.swipeActionRaw = swipeAction?.rawValue
        self.score = score
    }
}
