# Interface Contract: FeedViewModel（スキップ対応）

**Branch**: `002-skip-action` | **Date**: 2026-05-29

既存の `FeedViewModel` への追加・変更インターフェース。

---

## 追加メソッド

```swift
// スキップ操作
func skip(article: Article)
// - article.swipeAction を変更しない（SwiftData に書かない）
// - skippedURLsInSession に article.url を追加する
// - lastAction = .skipped(article: article) にセットする
// - context.save() は呼ばない
```

## 変更メソッド

```swift
// Undo（スキップ対応版）
func undo(context: ModelContext)
// - lastAction が .skipped の場合: skippedURLsInSession から url を除去する
// - lastAction が .swiped の場合: 既存動作（swipeAction を nil に戻す）
// - lastAction を nil にリセットする
```

## 変更プロパティ

```swift
// 削除: var lastSwipedArticle: Article?
// 追加: var lastAction: LastAction?

// Undo ボタン表示条件（FeedView 側）
// 変更前: viewModel.lastSwipedArticle != nil
// 変更後: viewModel.lastAction != nil
```

## LastAction enum

```swift
enum LastAction {
    case swiped(article: Article, kind: SwipeAction)
    case skipped(article: Article)

    var article: Article {
        switch self {
        case .swiped(let a, _): a
        case .skipped(let a): a
        }
    }
}
```

## 不変条件

- `skip()` は `PersonalizationService.recordSignal()` を**呼ばない**
- `skip()` は `Article.swipeAction` を**変更しない**
- `skippedURLsInSession` はアプリのプロセス生存期間中のみ保持される（再起動でクリア）
- `undo()` で `.skipped` を取り消した場合、`skippedURLsInSession` から除去するだけで SwiftData の変更は不要
