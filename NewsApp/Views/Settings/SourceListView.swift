import SwiftUI
import SwiftData

struct SourceListView: View {

    @Environment(\.modelContext) private var context
    @Query(sort: \NewsSource.addedAt) private var sources: [NewsSource]
    @Query private var signals: [InterestSignal]
    @StateObject private var viewModel = SettingsViewModel()

    @State private var showAddSheet = false
    @State private var newURL = ""
    @State private var newName = ""

    private var rankedSuggestions: [SuggestedSource] {
        SuggestedSources.ranked(excluding: Set(sources.map(\.feedURL)), signals: signals)
    }

    var body: some View {
        List {
            ForEach(sources) { source in
                VStack(alignment: .leading, spacing: 4) {
                    Text(source.name).font(.headline)
                    Text(source.feedURL).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                .accessibilityLabel("\(source.name), \(source.feedURL)")
            }
            .onDelete { indexSet in
                indexSet.forEach { viewModel.deleteSource(sources[$0], context: context) }
            }
        }
        .navigationTitle("ニュースソース")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("ソースを追加")
            }
            ToolbarItem(placement: .topBarLeading) { EditButton() }
        }
        .sheet(isPresented: $showAddSheet) {
            addSourceSheet
        }
        .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var addSourceSheet: some View {
        NavigationStack {
            Form {
                if !rankedSuggestions.isEmpty {
                    Section("おすすめ") {
                        ForEach(rankedSuggestions, id: \.feedURL) { suggestion in
                            Button(suggestion.name) {
                                try? viewModel.addSource(name: suggestion.name, feedURL: suggestion.feedURL, context: context)
                            }
                            .foregroundStyle(.primary)
                            .accessibilityLabel("\(suggestion.name)をおすすめソースとして追加")
                        }
                    }
                }
                Section("フィード URL") {
                    TextField("https://example.com/feed.xml", text: $newURL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                Section("表示名（省略可）") {
                    TextField("例: NHK ニュース", text: $newName)
                }
            }
            .navigationTitle("ソースを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { showAddSheet = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("追加") {
                        do {
                            try viewModel.addSource(name: newName, feedURL: newURL, context: context)
                            showAddSheet = false
                            newURL = ""
                            newName = ""
                        } catch {
                            viewModel.errorMessage = error.localizedDescription
                        }
                    }
                    .disabled(newURL.isEmpty)
                }
            }
        }
    }
}
