# Tasks: おすすめニュースソースサジェスト

**Input**: Design documents from `specs/005-news-source-suggestions/`

**Branch**: `005-news-source-suggestions` | **Date**: 2026-05-29

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 並列実行可能（異なるファイル、依存なし）
- **[Story]**: 対応するユーザーストーリー (US1/US2/US3)
- 各タスクに具体的なファイルパスを記載

---

## Phase 1: Setup（基盤確認）

**Purpose**: 既存テストの基準値確認とプロジェクト生成の準備

- [x] T001 既存28テスト全件パスを確認する（`xcodebuild test -scheme NewsApp -destination 'platform=iOS Simulator,name=iPhone Air,OS=26.4.1'`）

---

## Phase 2: Foundational（共通データモデル）

**Purpose**: 全ユーザーストーリーが依存する `SuggestedSource` 型とカタログを作成

**⚠️ CRITICAL**: このフェーズが完了するまでユーザーストーリー実装は開始しない

- [x] T00X `NewsApp/Models/SuggestedSource.swift` を新規作成し、`struct SuggestedSource: Hashable { let name: String; let feedURL: String }` と `enum SuggestedSources { static let all: [SuggestedSource] }` を定義する（カタログ内容は research.md の Decision 5 を参照、7件）
- [x] T00X `xcodegen generate` を実行して `SuggestedSource.swift` を Xcode プロジェクトに追加する

**Checkpoint**: Foundation ready — US1/US2/US3 の実装を開始できる

---

## Phase 3: User Story 1 - おすすめリストからワンタップ追加 (Priority: P1) 🎯 MVP

**Goal**: ソース追加シート上部におすすめリストを表示し、タップで即時追加・シートは開いたまま

**Independent Test**: ソースが1件も登録されていない状態でシートを開き、≥5件のおすすめが表示され、タップすると即座にニュースソース一覧に追加されることを Simulator で確認できる

### Tests for User Story 1 ⚠️ （TDD必須 — 実装前に書いて RED を確認）

- [x] T00X [P] [US1] `NewsAppTests/Unit/SuggestedSourcesTests.swift` を新規作成し、`testCatalogHasMinimumSources`（`SuggestedSources.all.count >= 5`）と `testCatalogURLsAreUnique`（feedURL が一意）を実装する
- [x] T00X [P] [US1] `NewsAppTests/Unit/SuggestedSourcesTests.swift` に `testFilteredSuggestionsReturnsAllWhenNoneAdded` を追加する — `SuggestedSources.filtered(excluding: [])` が全件返すことを検証する
- [x] T00X [US1] テストを実行し RED（失敗）を確認する（`xcodegen generate && xcodebuild test -scheme NewsApp -only-testing:NewsAppTests/Unit/SuggestedSourcesTests`）

### Implementation for User Story 1

- [x] T00X [US1] `NewsApp/Models/SuggestedSource.swift` に `SuggestedSources.filtered(excluding addedURLs: Set<String>) -> [SuggestedSource]` 静的メソッドを追加する（`all.filter { !addedURLs.contains($0.feedURL) }` で実装）
- [x] T00X [US1] `NewsApp/Views/Settings/SourceListView.swift` に `filteredSuggestions: [SuggestedSource]` computed property を追加する（`SuggestedSources.filtered(excluding: Set(sources.map(\.feedURL)))`）
- [x] T00X [US1] `NewsApp/Views/Settings/SourceListView.swift` の `addSourceSheet` `Form` 先頭に `if !filteredSuggestions.isEmpty { Section("おすすめ") { ForEach(filteredSuggestions, id: \.feedURL) { ... } } }` セクションを追加する
- [x] T0XX [US1] T009 の各行にタップハンドラを実装する — `viewModel.addSource(name: suggestion.name, feedURL: suggestion.feedURL, context: context)` を呼び出し、シートを閉じずに `try?` でエラーを `viewModel.errorMessage` に流す（`NewsApp/Views/Settings/SourceListView.swift`）
- [x] T0XX [US1] テストを実行し GREEN（28→33件以上）を確認する

**Checkpoint**: User Story 1 が独立して動作・テスト可能 — Simulator でタップ追加を確認

---

## Phase 4: User Story 2 - 追加済みソースの重複防止 (Priority: P2)

**Goal**: 追加済みのおすすめソースがリストから消え、全件追加済み時はセクション自体が非表示になる

**Independent Test**: 任意のおすすめソースを追加した後、同ソースがおすすめリストに表示されないことを Simulator で確認できる。全件追加後はセクション自体が消えることを確認。

### Tests for User Story 2 ⚠️ （実装前に書いて RED を確認）

- [x] T0XX [P] [US2] `NewsAppTests/Unit/SuggestedSourcesTests.swift` に `testFilteredSuggestionsExcludesAddedURLs` を追加する — 1件の URL を除外した結果を検証する
- [x] T0XX [P] [US2] `NewsAppTests/Unit/SuggestedSourcesTests.swift` に `testFilteredSuggestionsIsEmptyWhenAllAdded` を追加する — 全件 URL を除外すると空配列になることを検証する
- [x] T0XX [US2] テストを実行し RED（失敗）を確認する

### Implementation for User Story 2

- [x] T0XX [US2] T007 で実装した `SuggestedSources.filtered` が既にフィルタリングをカバーしていることを確認し、T012/T013 のテストを GREEN にする（追加実装が不要な場合はそのまま通過）
- [x] T0XX [US2] T009 の `if !filteredSuggestions.isEmpty` ガードが全件追加済み時にセクション自体を非表示にすることを Simulator で目視確認する（`NewsApp/Views/Settings/SourceListView.swift`）
- [x] T0XX [US2] テストを実行し全件 GREEN を確認する

**Checkpoint**: User Stories 1 + 2 が独立して動作 — 重複防止が機能することを確認

---

## Phase 5: User Story 3 - 手動 URL 入力との共存 (Priority: P3)

**Goal**: おすすめリスト表示中も URL 手動入力フォームが引き続き動作する

**Independent Test**: おすすめセクションが表示されている状態で、URL フィールドに直接入力して「追加」をタップし、ソースが追加されることを Simulator で確認できる

### Tests for User Story 3 ⚠️ （実装前に書いて RED を確認）

- [x] T0XX [US3] `NewsAppTests/Unit/SettingsViewModelTests.swift` に `testAddSourceStillWorksWithCustomURL` を追加する — おすすめリストにないカスタム URL のソースが正常に追加できることを検証する

### Implementation for User Story 3

- [x] T0XX [US3] `NewsApp/Views/Settings/SourceListView.swift` の `addSourceSheet` で「フィード URL」`Section` と「表示名」`Section` が おすすめ `Section` の下に引き続き存在することを確認し、必要であれば順序を整える（コード変更不要の場合は目視確認で完了）
- [x] T0XX [US3] 全テストを実行し GREEN（≥33件）を確認する（既存28件のリグレッションなし）

**Checkpoint**: 全ユーザーストーリーが独立して動作・テスト可能

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: 動作確認・アクセシビリティ・最終検証

- [x] T0XX [P] `NewsApp/Views/Settings/SourceListView.swift` のおすすめ行に `.accessibilityLabel("\(suggestion.name)をおすすめソースとして追加")` を追加する（Constitution IV: Accessibility 準拠）
- [x] T0XX quickstart.md の全チェックリスト項目を Simulator（iPhone Air / iOS 26.4.1）で目視確認する
- [x] T0XX `xcodegen generate` を実行後、全テストスイートを実行し最終 GREEN を確認する

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: 依存なし — 即座に開始可能
- **Foundational (Phase 2)**: Phase 1 完了後 — 全ストーリーをブロック
- **US1 (Phase 3)**: Phase 2 完了後に開始 — US2/US3 に依存しない
- **US2 (Phase 4)**: Phase 2 完了後（US1 と並列可能） — US1 の実装を流用
- **US3 (Phase 5)**: Phase 2 完了後（US1/US2 と並列可能）
- **Polish (Phase 6)**: 全ユーザーストーリー完了後

### User Story Dependencies

- **US1 (P1)**: Phase 2 完了後に独立して実装可能
- **US2 (P2)**: Phase 2 完了後に独立して実装可能。US1 の `SuggestedSources.filtered` を再利用。
- **US3 (P3)**: Phase 2 完了後に独立して実装可能。既存コードへのリグレッション確認が主。

### Within Each User Story

1. テスト作成 → RED 確認
2. 実装
3. GREEN 確認
4. チェックポイントで独立動作を検証

### Parallel Opportunities

- T004・T005（US1 テスト作成）は並列実行可能
- T012・T013（US2 テスト作成）は並列実行可能
- US2・US3 は US1 のチェックポイント後に並列開始可能（個人アプリのため通常は順次）

---

## Parallel Example: User Story 1

```bash
# US1 テスト（並列作成可能）:
Task: T004 - SuggestedSourcesTests.swift にカタログ系テストを追加
Task: T005 - SuggestedSourcesTests.swift にフィルタリング基本テストを追加

# US1 実装（順次）:
Task: T007 - filtered メソッド追加
Task: T008 - computed property 追加
Task: T009 - UI Section 追加
Task: T010 - タップハンドラ追加
```

---

## Implementation Strategy

### MVP First（User Story 1 のみ）

1. Phase 1: テスト基準確認
2. Phase 2: `SuggestedSource.swift` 作成
3. Phase 3: US1 全タスク完了
4. **STOP & VALIDATE**: Simulator でタップ追加を確認
5. テスト33件以上 GREEN でデモ可能な MVP 完成

### Incremental Delivery

1. Setup + Foundational → 共通基盤完成
2. US1 → MVP完成（タップ追加）
3. US2 → 重複防止追加（フィルタリング・自動消去）
4. US3 → 既存フロー確認
5. Polish → アクセシビリティ・最終検証

---

## Notes

- [P] = 異なるファイルへの変更で依存なし、並列実行可能
- TDD 必須（Constitution III）: 各ストーリーでテスト RED → 実装 → GREEN の順を厳守
- `viewModel.addSource` はエラー処理済み（`SettingsViewModel`）— 追加実装不要
- おすすめの RSS URL は実装前にブラウザで有効性を確認すること（research.md Decision 5 参照）
- quickstart.md のチェックリストを最終確認に使用する
