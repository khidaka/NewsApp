# Data Model: スキップ記事の永続的非表示

**Branch**: `006-skip-persist` | **Date**: 2026-05-29

## 変更エンティティ: Article（既存モデルの拡張）

### 追加フィールド

| フィールド | 型 | デフォルト値 | 説明 |
|-----------|-----|------------|------|
| `isSkipped` | `Bool` | `false` | スキップ済みフラグ。`true` の場合フィードから除外 |

### 変更後のエンティティ全体像

```
Article
├── url: String (unique, primary key)
├── id: UUID
├── title: String
├── summary: String
├── sourceName: String
├── sourceURL: String
├── fetchedAt: Date
├── swipeActionRaw: String? (shared / notInterested)
├── score: Double
└── isSkipped: Bool (NEW, default: false)
```

### バリデーションルール

- `isSkipped = true` かつ `swipeActionRaw != nil` は許容しない（スキップは swipeAction を設定しないため、共存は起こりえない）
- `isSkipped = false` → フィードに表示対象
- `isSkipped = true` → フィードから永続的に除外

### 状態遷移

```
[未操作] ──skip()──> [isSkipped=true]
                          │
                     undo() ↓
                    [isSkipped=false (未操作に戻る)]
```

## 削除要素: FeedViewModel.skippedURLsInSession

現行の `@Published var skippedURLsInSession: Set<String>` は `Article.isSkipped` で置き換えられるため削除。

## フィルタリングロジック変更

### 変更前（FeedView）
```swift
@Query(filter: #Predicate<Article> { $0.swipeActionRaw == nil }, ...)
private var articles: [Article]

private var visibleArticles: [Article] {
    articles.filter { !viewModel.skippedURLsInSession.contains($0.url) }
}
// cardStack では visibleArticles を使用
```

### 変更後（FeedView）
```swift
@Query(filter: #Predicate<Article> { $0.swipeActionRaw == nil && !$0.isSkipped }, ...)
private var articles: [Article]
// visibleArticles は不要、cardStack で articles を直接使用
```
