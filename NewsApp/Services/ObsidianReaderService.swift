import Foundation
import NaturalLanguage

struct ObsidianContext {
    var keywords: [String: Int]
    var lastScannedAt: Date
}

protocol ObsidianReaderServiceProtocol {
    func extractKeywords(from bookmarkData: Data) async throws -> [String: Int]
    func saveVaultBookmark(for folderURL: URL) throws
}

// MARK: - Implementation

final class ObsidianReaderService: ObsidianReaderServiceProtocol {

    private let defaults = UserDefaults.standard
    static let bookmarkKey = "obsidian_vault_bookmark"

    func saveVaultBookmark(for folderURL: URL) throws {
        let bookmark = try folderURL.bookmarkData(
            options: .minimalBookmark,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        defaults.set(bookmark, forKey: Self.bookmarkKey)
    }

    func extractKeywords(from bookmarkData: Data) async throws -> [String: Int] {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmarkData,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        guard url.startAccessingSecurityScopedResource() else {
            throw ObsidianError.accessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }

        return try await Task.detached(priority: .utility) {
            try self.scanVault(at: url)
        }.value
    }

    // MARK: - Private

    private func scanVault(at url: URL) throws -> [String: Int] {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [:] }

        var freq: [String: Int] = [:]
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "md" else { continue }
            let text = (try? String(contentsOf: fileURL, encoding: .utf8)) ?? ""
            let stripped = stripFrontmatter(from: text)
            for kw in extractKeywords(from: stripped) {
                freq[kw, default: 0] += 1
            }
        }
        return freq
    }

    private func stripFrontmatter(from text: String) -> String {
        guard text.hasPrefix("---") else { return text }
        let lines = text.components(separatedBy: "\n")
        var endIndex = 1
        while endIndex < lines.count {
            if lines[endIndex].trimmingCharacters(in: .whitespaces) == "---" {
                return lines.dropFirst(endIndex + 1).joined(separator: "\n")
            }
            endIndex += 1
        }
        return text
    }

    private func extractKeywords(from text: String) -> [String] {
        var keywords: [String] = []
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

enum ObsidianError: Error {
    case accessDenied
    case noBookmark
}
