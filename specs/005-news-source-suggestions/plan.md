# Implementation Plan: おすすめニュースソースサジェスト

**Branch**: `005-news-source-suggestions` | **Date**: 2026-05-29 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/005-news-source-suggestions/spec.md`

## Summary

ソース追加シートの上部に、アプリにバンドルされた静的おすすめソース一覧（≥7件）を表示する。ユーザーがタップすると即座に追加され、シートは開いたまま連続追加できる。既登録ソースはフィルタリングで非表示。既存 `SettingsViewModel.addSource` を再利用し、新たな SwiftData モデルは追加しない。

## Technical Context

**Language/Version**: Swift 5.9 / iOS 17.0+

**Primary Dependencies**: SwiftUI, SwiftData, FeedKit (SPM) — 本機能に追加依存なし

**Storage**: SwiftData (`NewsSource` モデル — 既存、変更なし)

**Testing**: XCTest

**Target Platform**: iOS 17.0+

**Project Type**: iOS モバイルアプリ（個人用）

**Performance Goals**: タップ後 1 秒以内に画面更新 (SC-004)。静的データのため追加遅延なし。

**Constraints**: オフライン動作必須。静的リストのみ（ネットワーク取得なし）。

**Scale/Scope**: 個人用アプリ。おすすめソース数 7 件。

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Content-First Architecture | ✅ Pass | ソース追加はコンテンツ取得の前提。直接改善。 |
| II. Performance & Reliability | ✅ Pass | 静的配列のフィルタリングのみ。UI への追加遅延ゼロ。 |
| III. Test-First Development | ✅ Pass | `SuggestedSourcesTests` を実装前に作成する。 |
| IV. User Experience Excellence | ✅ Pass | 既存 Form/Section 拡張。UI 要素追加はシナリオに対応済み。 |
| V. Simplicity & Maintainability | ✅ Pass | 新モデルなし。既存 ViewModel 再利用。最小変更で実現。 |

**Gate**: すべての原則を通過。Complexity Tracking 不要。

## Project Structure

### Documentation (this feature)

```text
specs/005-news-source-suggestions/
├── plan.md              # This file
├── research.md          # Phase 0: 設計決定
├── data-model.md        # Phase 1: SuggestedSource 型・フィルタリング設計
├── quickstart.md        # Phase 1: ビルド・検証手順
├── checklists/
│   └── requirements.md  # スペック品質チェックリスト
└── tasks.md             # Phase 2 (/speckit-tasks で生成)
```

### Source Code Changes

```text
NewsApp/
└── Models/
    └── SuggestedSource.swift          # NEW: struct SuggestedSource + SuggestedSources.all

NewsApp/
└── Views/
    └── Settings/
        └── SourceListView.swift       # MODIFIED: おすすめセクション追加

NewsAppTests/
└── Unit/
    └── SuggestedSourcesTests.swift    # NEW: フィルタリングロジックのユニットテスト
```

**Structure Decision**: 既存の `Models/` に `SuggestedSource.swift` を追加し、既存 `Views/Settings/SourceListView.swift` を最小限変更。新規フォルダ不要。

## Implementation Approach

### Step 1 (TDD — RED): テスト作成

`NewsAppTests/Unit/SuggestedSourcesTests.swift` に以下を実装:

```swift
// 1. カタログに5件以上含まれる
func testCatalogHasMinimumSources()

// 2. 全URLが一意である
func testCatalogURLsAreUnique()

// 3. 未追加ソースがすべて返される
func testFilteredSuggestionsReturnsAllWhenNoneAdded()

// 4. 追加済みURLが除外される
func testFilteredSuggestionsExcludesAddedURLs()

// 5. 全件追加済み時に空配列が返される
func testFilteredSuggestionsIsEmptyWhenAllAdded()
```

フィルタリングロジックはテスト可能な純粋関数として抽出:

```swift
func filteredSuggestions(all: [SuggestedSource], addedURLs: Set<String>) -> [SuggestedSource] {
    all.filter { !addedURLs.contains($0.feedURL) }
}
```

### Step 2 (TDD — GREEN): 実装

1. `NewsApp/Models/SuggestedSource.swift` 作成
   - `struct SuggestedSource: Hashable`
   - `enum SuggestedSources` と `static let all`

2. `SourceListView.swift` 修正
   - `filteredSuggestions` computed property 追加
   - `addSourceSheet` の `Form` 先頭に `Section("おすすめ")` 追加
   - タップ時に `viewModel.addSource(name:feedURL:context:)` を呼ぶ

### Step 3: リファクタリングと検証

- 全テスト実行（28件 → 33件以上を確認）
- Simulator 上で動作確認（quickstart.md のチェックリスト全項目）

## Key Design Notes

- `filteredSuggestions` はテスト用にフリー関数として抽出し、`SourceListView` のプロパティからも呼ぶ
- `SuggestedSources.all` の URL 有効性は実装時にブラウザで確認すること（RSS フィードは廃止されている場合がある）
- タップ時のエラー処理は既存 `viewModel.errorMessage` アラートで対応（追加実装不要）
