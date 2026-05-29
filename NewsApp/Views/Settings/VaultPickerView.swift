import SwiftUI

struct VaultPickerView: View {

    @State private var showPicker = false
    @State private var selectedPath: String = {
        guard let data = UserDefaults.standard.data(forKey: ObsidianReaderService.bookmarkKey) else { return "" }
        var stale = false
        let url = try? URL(resolvingBookmarkData: data, bookmarkDataIsStale: &stale)
        return url?.path ?? ""
    }()
    @State private var errorMessage: String? = nil

    private let service = ObsidianReaderService()

    var body: some View {
        Form {
            Section("Obsidian Vault フォルダ") {
                if selectedPath.isEmpty {
                    Text("未設定").foregroundStyle(.secondary)
                } else {
                    Text(selectedPath)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Button("フォルダを選択") {
                    showPicker = true
                }
            }
            Section {
                Text("設定したフォルダ内の Markdown ファイルをアプリ起動時に読み取り、ニュースのパーソナライズに使用します。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Obsidian Vault")
        .sheet(isPresented: $showPicker) {
            FolderPickerRepresentable { url in
                guard let url else { return }
                do {
                    try service.saveVaultBookmark(for: url)
                    selectedPath = url.path
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
        .alert("エラー", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
}

// MARK: - UIDocumentPickerViewController wrapper

import UIKit

private struct FolderPickerRepresentable: UIViewControllerRepresentable {
    let onPick: (URL?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uvc: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL?) -> Void
        init(onPick: @escaping (URL?) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPick(urls.first)
        }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onPick(nil)
        }
    }
}
