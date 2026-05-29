# Research: スキップアクション

**Branch**: `002-skip-action` | **Date**: 2026-05-29

---

## 1. セッションスコープ状態の管理

**Decision**: `FeedViewModel` に `skippedURLsInSession: Set<String>` をインメモリで持つ

**Rationale**:
- スキップは永続化不要（再起動でリセット）
- SwiftData `@Model` に `.skipped` を追加すると永続化されてしまい仕様違反
- `Set<String>` で URL を管理することで O(1) ルックアップ

**Alternatives considered**:
- `Article` に一時フラグ追加 → `@Model` は SwiftData が管理するため副作用が大きい
- `@AppStorage` → 永続化されてしまい仕様違反

---

## 2. @Query フィルタリングとセッション除外の共存

**Decision**: `@Query` は `swipeActionRaw == nil` のままにして、`FeedView` 内でさらに `skippedURLsInSession` で絞り込む

**Rationale**:
- `@Query` の `#Predicate` は SwiftData の永続データのみ参照可能（ViewModel のメモリ状態は参照できない）
- `FeedView` のボディで `articles.filter { !viewModel.skippedURLsInSession.contains($0.url) }` を計算すれば十分
- スキップは最大数十件程度のため線形フィルタのパフォーマンス問題なし

---

## 3. Undo のスキップ対応

**Decision**: `lastAction` を `enum` で型安全に管理する

```swift
enum LastAction {
    case swiped(article: Article, kind: SwipeAction)
    case skipped(article: Article)
}
```

**Rationale**:
- 既存の `lastSwipedArticle: Article?` + 追加フラグより、1つの enum で状態を表現する方が安全
- Undo 時に `kind` を見て適切な処理（シグナル取り消し or セッション除外解除）を選択できる

---

## 4. 上スワイプジェスチャーの実装

**Decision**: 既存の `DragGesture` を拡張して縦方向も検知する

**Rationale**:
- `CardView` はすでに `DragGesture` を持っている
- `value.translation.height < -threshold` で上スワイプを判定（上方向はマイナス）
- 閾値は縦 120pt 程度（横の 40% 閾値より小さめ — 縦は意図的な操作に必要な距離が短い）
- 左右スワイプと競合しないよう `abs(width) > abs(height)` の場合は横優先

---

## 5. スキップボタンの配置

**Decision**: `CardView` 右上に小さいスキップアイコン（`forward.end` SF Symbol）を配置

**Rationale**:
- 上スワイプを知らないユーザーへのディスカバリビリティ確保
- 右上は「次へ」の文脈としてユーザーが直感的に理解しやすい位置
- タップ領域 ≥44pt を確保（WCAG 2.1 AA 準拠）
