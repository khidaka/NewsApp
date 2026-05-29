---
description: "Task list for 007-smart-source-suggestions: 利用統計に基づくおすすめソースの自動調整"
---

# Tasks: 利用統計に基づくおすすめソースの自動調整

**Input**: Design documents from `specs/007-smart-source-suggestions/`

**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅

**TDD Note**: Constitution 原則 III により TDD 必須。`ranked(...)` は純粋関数なのでテスト先行が容易。テストが失敗することを確認してから実装に進む。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 並行実行可能（異なるファイル、未完了タスクへの依存なし）
- **[Story]**: 対応ユーザーストーリー（US1 / US2）

---

## Phase 1: Foundational（ブロッキング前提条件）

**Purpose**: `SuggestedSource` への `keywords` 追加。両ユーザーストーリーが依存する基盤。

**⚠️ CRITICAL**: このフェーズが完了するまで US1・US2 のいずれも開始できない

- [x] T001 Add `keywords: [String]` field to `SuggestedSource` struct and assign representative keywords to all 7 sources in `NewsApp/Models/SuggestedSource.swift`

**Checkpoint**: `SuggestedSource.keywords` が利用可能 — ユーザーストーリー実装を開始できる

---

## Phase 2: User Story 1 — 利用傾向に合ったおすすめが上位に表示される (Priority: P1) 🎯 MVP

**Goal**: `SuggestedSources.ranked(excluding:signals:)` 純粋関数を実装し、`SourceListView` で利用傾向順に並び替えて表示する

**Independent Test**: 記事を共有/興味なし操作した後、ソース追加シートを開いて、傾向に対応するおすすめが上位に並ぶことを確認

### Tests for User Story 1（TDD: 実装前に記述・失敗を確認）⚠️

> **NOTE: T001 完了後、T002 を記述してビルドエラー/テスト失敗を確認してから T003 に進む**

- [x] T002 [P] [US1] Write failing TDD tests for `ranked(excluding:signals:)` in `NewsAppTests/Unit/SuggestedSourcesTests.swift`: add `testRanked_noSignals_returnsDefaultOrder()`, `testRanked_positiveSignal_promotesMatchingSource()`, `testRanked_negativeSignal_demotesMatchingSource()`, `testRanked_tieBreak_preservesDefinitionOrder()`

### Implementation for User Story 1

- [x] T003 [US1] Implement `SuggestedSources.ranked(excluding:signals:)` pure function in `NewsApp/Models/SuggestedSource.swift`: build keyword weight map from signals (shared +2 / notInterested -3), compute score per source, sort descending with index-based tie-break
- [x] T004 [US1] Add `@Query private var signals: [InterestSignal]` to `SourceListView` in `NewsApp/Views/Settings/SourceListView.swift`
- [x] T005 [US1] Replace `filteredSuggestions` computed property with `SuggestedSources.ranked(excluding: Set(sources.map(\.feedURL)), signals: signals)` call in `NewsApp/Views/Settings/SourceListView.swift`

**Checkpoint**: US1 独立テスト可能 — `xcodebuild test` で T002 のテストが pass し、シートを開いて利用傾向が反映されることを確認

---

## Phase 3: User Story 2 — 追加済みソースは引き続き除外される (Priority: P2)

**Goal**: 並び替え後も追加済みソースがおすすめに表示されず、feature 005 の重複防止が維持される

**Independent Test**: いくつかのソースを追加した後、おすすめリストにそれらが含まれず、残りが利用傾向順で並ぶことを確認

### Tests for User Story 2（TDD: 実装前に記述）⚠️

- [x] T006 [P] [US2] Write TDD test `testRanked_excludesAddedSources()` in `NewsAppTests/Unit/SuggestedSourcesTests.swift`: verify that sources with feedURLs in the `excluding` set do not appear in the result

### Verification for User Story 2

- [x] T007 [US2] Verify `ranked(excluding:signals:)` already handles exclusion (inherits from `filtered` logic in T003) — confirm T006 passes without additional changes

**Checkpoint**: US1 AND US2 が独立動作 — スコアリングと重複防止の両方が pass

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: 最終検証とドキュメント更新

- [x] T008 Run `xcodebuild test -scheme NewsApp -destination 'platform=iOS Simulator,name=iPhone Air,OS=26.4.1'` and confirm all tests pass (44 existing + new ranked tests)
- [ ] T009 [P] Manual validation per `specs/007-smart-source-suggestions/quickstart.md`: run SC-001, SC-002, SC-003, SC-004 checklist on simulator
- [x] T010 [P] Update `CLAUDE.md` feature table and design notes to reflect `SuggestedSources.ranked(...)` replaces `SuggestedSources.filtered(...)`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: 依存なし — 即座に開始可能
- **User Story 1 (Phase 2)**: T001 完了後に開始可能
- **User Story 2 (Phase 3)**: T003 完了後に開始可能（ranked の excluding 引数が実装されていること）
- **Polish (Phase 4)**: US1・US2 両フェーズ完了後

### Within Each User Story

1. テストを先行記述（TDD）→ 失敗を確認
2. 純粋関数を実装（T003）
3. View を統合（T004, T005）
4. テストが pass することを確認

### Parallel Opportunities

- T002 と T006 は独立したテストメソッドの追加のため並行記述可能
- T004 と T003 は依存関係なし（T004 は @Query 追加のみ）ため並行可
- T009 と T010 は並行実行可能

---

## Parallel Example: User Story 1

```bash
# TDD Step 1 — テスト記述（T002）
Task: "Write testRanked_noSignals_returnsDefaultOrder etc. in SuggestedSourcesTests.swift"

# T001 完了後、T002 のテストが失敗することを確認してから以下を並行実施

# TDD Step 2 — 実装（T003, T004 は並行可）
Task T003: "Implement SuggestedSources.ranked() in SuggestedSource.swift"
Task T004: "Add @Query signals to SourceListView.swift"
# T003 完了後
Task T005: "Replace filteredSuggestions with ranked() in SourceListView.swift"

# テストが pass することを確認
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. T001 完了（`keywords` 追加）
2. T002 完了（テスト先行）
3. T003 → T004 → T005 完了（ランキング実装 + View 統合）
4. **STOP and VALIDATE**: シミュレータでおすすめが傾向順に並ぶことを確認
5. 問題なければ US2 (Phase 3) と Polish へ進む

### Incremental Delivery

1. T001 完了 → 基盤準備
2. T002–T005 完了 → ランキング機能が動作（MVP）
3. T006–T007 完了 → 除外機能の回帰確認も完了
4. T008–T010 完了 → 全テスト pass、ドキュメント更新

---

## Notes

- `ranked(excluding:signals:)` は入出力が明確な純粋関数のため、TDD サイクル（赤→緑→リファクタ）が容易
- `@Query private var signals: [InterestSignal]` の追加（T004）は `SourceListView` に1行加えるだけで `filteredSuggestions` からの変更に依存しない
- `ranked()` 内の重みマップ集計は `PersonalizationService.buildWeightMap` と同パターンだが、`PersonalizationService` を直接呼ばず独立実装する（View からサービス依存を増やさない）
- SwiftData マイグレーション不要（`SuggestedSource` は非永続 struct）
