# Data Model: スキップアクション

**Branch**: `002-skip-action` | **Date**: 2026-05-29

---

## SwiftData スキーマ変更

**なし** — SwiftData モデル（Article・NewsSource・InterestSignal）への変更は不要。
スキップはセッション限定のためデータベースに記録しない。

---

## FeedViewModel の状態追加（インメモリ）

### 追加フィールド

| フィールド | 型 | 説明 |
|-----------|-----|------|
| `skippedURLsInSession` | `Set<String>` | セッション中にスキップした記事の URL セット。アプリ終了でクリア |
| `lastAction` | `LastAction?` | 直前のアクション（Undo 用）。既存の `lastSwipedArticle` を置き換え |

### LastAction enum（新規）

```swift
enum LastAction {
    case swiped(article: Article, kind: SwipeAction)  // 右スワイプ or 左スワイプ
    case skipped(article: Article)                     // スキップ
}
```

### 削除フィールド

| フィールド | 理由 |
|-----------|------|
| `lastSwipedArticle: Article?` | `lastAction` に統合されるため削除 |

---

## FeedView のフィルタリングロジック

```swift
// @Query は swipeActionRaw == nil のまま変更なし
// FeedView のボディで追加フィルタ適用
var visibleArticles: [Article] {
    articles.filter { !viewModel.skippedURLsInSession.contains($0.url) }
}
```

---

## 変更対象ファイル一覧

| ファイル | 変更種別 | 内容 |
|---------|---------|------|
| `NewsApp/ViewModels/FeedViewModel.swift` | 更新 | `skippedURLsInSession`・`lastAction` 追加、`skip()` メソッド追加、`undo()` 拡張 |
| `NewsApp/Views/Feed/CardView.swift` | 更新 | 上スワイプジェスチャー追加、スキップボタン追加 |
| `NewsApp/Views/Feed/FeedView.swift` | 更新 | `visibleArticles` フィルタ追加、スキップ操作の配線、Undo ボタンの条件更新 |
