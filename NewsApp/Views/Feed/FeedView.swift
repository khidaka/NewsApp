import SwiftUI
import SwiftData

struct FeedView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.obsidianContext) private var obsidianContext
    @Query(
        filter: #Predicate<Article> { $0.swipeActionRaw == nil },
        sort: \Article.score,
        order: .reverse
    )
    private var articles: [Article]

    @StateObject private var viewModel = FeedViewModel()
    @State private var shareItem: Article? = nil

    // スキップ済みを除外した表示用リスト
    private var visibleArticles: [Article] {
        articles.filter { !viewModel.skippedURLsInSession.contains($0.url) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if visibleArticles.isEmpty && !viewModel.isLoading {
                    emptyState
                } else {
                    cardStack
                }

                if viewModel.isLoading {
                    ProgressView("取得中…")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .navigationTitle("ニュース")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.reload(context: context, obsidianContext: obsidianContext) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("ニュースを更新")
                    .disabled(viewModel.isLoading)
                }

                if viewModel.lastAction != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            viewModel.undo(context: context)
                        } label: {
                            Label("取り消し", systemImage: "arrow.uturn.backward")
                        }
                        .accessibilityLabel("直前の操作を取り消す")
                    }
                }
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(item: $shareItem) { article in
                if let url = URL(string: article.url) {
                    ShareSheet(url: url, title: article.title)
                }
            }
        }
    }

    // MARK: - Subviews

    private var cardStack: some View {
        ZStack {
            ForEach(visibleArticles.prefix(3).reversed()) { article in
                CardView(
                    article: article,
                    onSwipeRight: {
                        shareItem = article
                        Task { await viewModel.swipeRight(article: article, context: context) }
                    },
                    onSwipeLeft: {
                        Task { await viewModel.swipeLeft(article: article, context: context) }
                    },
                    onSkip: {
                        viewModel.skip(article: article)
                    }
                )
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "newspaper")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("ニュースがありません")
                .font(.title3)
            Text("設定からニュースソースを追加してください")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            NavigationLink("設定を開く") {
                SettingsView()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .accessibilityElement(children: .combine)
    }
}
