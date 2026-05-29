import Foundation
import SwiftData

@MainActor
final class SettingsViewModel: ObservableObject {

    @Published var errorMessage: String? = nil

    func addSource(name: String, feedURL: String, context: ModelContext) throws {
        let trimmed = feedURL.trimmingCharacters(in: .whitespaces)
        guard let url = URL(string: trimmed), url.scheme == "https" || url.scheme == "http" else {
            throw SourceError.invalidURL
        }
        let source = NewsSource(name: name.isEmpty ? trimmed : name, feedURL: trimmed)
        context.insert(source)
        try context.save()
    }

    func deleteSource(_ source: NewsSource, context: ModelContext) {
        context.delete(source)
        try? context.save()
    }
}

enum SourceError: LocalizedError {
    case invalidURL
    var errorDescription: String? {
        switch self {
        case .invalidURL: "有効な URL を入力してください（http:// または https://）"
        }
    }
}
