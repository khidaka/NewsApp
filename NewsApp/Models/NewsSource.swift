import Foundation
import SwiftData

@Model
final class NewsSource {
    @Attribute(.unique) var feedURL: String
    var id: UUID
    var name: String
    var isEnabled: Bool
    var addedAt: Date

    init(name: String, feedURL: String, isEnabled: Bool = true) {
        self.id = UUID()
        self.name = name
        self.feedURL = feedURL
        self.isEnabled = isEnabled
        self.addedAt = .now
    }
}
