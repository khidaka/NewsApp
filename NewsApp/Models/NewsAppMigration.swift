import Foundation
import SwiftData

// MARK: - Schema V1 (isSkipped 追加前)

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] = [Article.self, NewsSource.self, InterestSignal.self]

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

        init(url: String = "", title: String = "", summary: String = "",
             sourceName: String = "", sourceURL: String = "",
             fetchedAt: Date = Date(), swipeActionRaw: String? = nil,
             score: Double = 0.0) {
            self.id = UUID()
            self.url = url
            self.title = title
            self.summary = summary
            self.sourceName = sourceName
            self.sourceURL = sourceURL
            self.fetchedAt = fetchedAt
            self.swipeActionRaw = swipeActionRaw
            self.score = score
        }
    }
}

// MARK: - Schema V2 (isSkipped: Bool = false を追加)

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] = [Article.self, NewsSource.self, InterestSignal.self]
}

// MARK: - Migration Plan

enum NewsAppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [SchemaV1.self, SchemaV2.self]
    static var stages: [MigrationStage] = [migrateV1toV2]

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )
}
