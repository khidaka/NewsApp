# Research: スキップ記事の永続的非表示

**Branch**: `006-skip-persist` | **Date**: 2026-05-29

## Decision 1: 永続化方式

**Decision**: `Article` モデルに `isSkipped: Bool` フラグを追加する

**Rationale**:
- SwiftData で管理される `Article` が既にすべての記事メタデータを持つ
- 別エンティティ (`SkippedArticle`) を作ると JOIN 相当の処理が必要になり複雑さが増す
- `@Query` の `#Predicate` は同一モデルのフィールドを直接参照できるため、`Article.isSkipped == false` でそのまま絞り込み可能
- Constitution 原則 V (Simplicity): YAGNI — 別エンティティが必要な具体的な理由がない

**Alternatives Considered**:
- `SkippedArticle` (別 SwiftData モデル): URL を格納するだけで Article への参照は不要。しかし `FeedView` のクエリが複雑化し、アンドゥ時の整合性管理が増える。不採用。
- セッション変数のまま `UserDefaults` に永続化: 型安全性に欠け、SwiftData との二重管理になる。不採用。

## Decision 2: `skippedURLsInSession` の扱い

**Decision**: `FeedViewModel.skippedURLsInSession` を削除し、SwiftData に一本化する

**Rationale**:
- `Article.isSkipped` が永続化されれば、セッション変数は完全に不要
- `@Query` が自動的に SwiftData の変更を監視するため、フィルタリングはリアクティブに更新される
- `FeedView.visibleArticles` 計算プロパティも不要になり、コードが簡潔になる

**Migration Impact**:
- 既存テスト `FeedViewModelSkipTests` の `skippedURLsInSession` 参照をすべて更新が必要
- `FeedView.visibleArticles` プロパティを削除し、`@Query` フィルタに統合

## Decision 3: SwiftData マイグレーション

**Decision**: `VersionedSchema` / `MigrationPlan` を使わず、`isSkipped` のデフォルト値 `false` で自動マイグレーション

**Rationale**:
- 個人用アプリかつ開発中のため軽量マイグレーションで十分
- SwiftData はスキーマ変更時にデフォルト値を持つ新規フィールドを自動的に追加できる
- 本番データが大量にある場合は `MigrationPlan` が必要だが現時点では不要

## Decision 4: `@Query` フィルタの更新

**Decision**: `FeedView` の `@Query` predicate を `swipeActionRaw == nil && isSkipped == false` に変更

**Current**:
```swift
filter: #Predicate<Article> { $0.swipeActionRaw == nil }
```

**New**:
```swift
filter: #Predicate<Article> { $0.swipeActionRaw == nil && !$0.isSkipped }
```

**Rationale**: `@Query` レベルでフィルタリングすることで SwiftData が SQLite クエリ最適化を行い、1000件超のスキップ記録でも高速動作（SC-004 の成功基準を満たす）

## Decision 5: アンドゥ実装

**Decision**: `undo()` の `.skipped` ケースで `article.isSkipped = false` + `context.save()` を実行

**Rationale**:
- 現行の `.swiped` ケースと対称的な実装になる（`context.save()` パターンを踏襲）
- アンドゥ後にアプリを再起動した場合、記事は正しく表示される（SC からの要件）
