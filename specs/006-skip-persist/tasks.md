---
description: "Task list for 006-skip-persist: スキップ記事の永続的非表示"
---

# Tasks: スキップ記事の永続的非表示

**Input**: Design documents from `specs/006-skip-persist/`

**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅

**TDD Note**: Constitution 原則 III により TDD 必須。テストタスクは実装タスクの前に配置。テストが失敗することを確認してから実装に進む。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 並行実行可能（異なるファイル、未完了タスクへの依存なし）
- **[Story]**: 対応ユーザーストーリー（US1 / US2）

---

## Phase 1: Foundational（ブロッキング前提条件）

**Purpose**: 両ユーザーストーリーが依存する `Article.isSkipped` フィールドの追加

**⚠️ CRITICAL**: このフェーズが完了するまで US1・US2 のいずれも開始できない

- [x] T001 Add `isSkipped: Bool = false` field to `Article` model in `NewsApp/Models/Article.swift`

**Checkpoint**: `Article.isSkipped` が使用可能 — ユーザーストーリー実装を開始できる

---

## Phase 2: User Story 1 — スキップした記事が再起動後も非表示になる (Priority: P1) 🎯 MVP

**Goal**: スキップ操作で `isSkipped = true` が SwiftData に永続化され、`@Query` フィルタによりフィード再起動後も除外される

**Independent Test**: 記事をスキップ → アプリ再起動 → スキップ記事がフィードに現れないことを確認

### Tests for User Story 1（TDD: 実装前に記述・失敗を確認）⚠️

> **NOTE: T001 完了後、T002 を記述して失敗することを確認してから T003 に進む**

- [x] T002 [P] [US1] Write failing TDD tests for persistent skip in `NewsAppTests/Unit/FeedViewModelSkipTests.swift`: add `testSkip_setsIsSkippedTrue()` and `testSkip_savesToContext()` that call `skip(article:context:)` with the new signature

### Implementation for User Story 1

- [x] T003 [US1] Update `FeedViewModel.skip()` in `NewsApp/ViewModels/FeedViewModel.swift`: add `context: ModelContext` parameter, set `article.isSkipped = true`, call `context.save()`, remove `skippedURLsInSession.insert()`
- [x] T004 [US1] Update `FeedView.swift` in `NewsApp/Views/Feed/FeedView.swift`: extend `@Query` filter to `$0.swipeActionRaw == nil && !$0.isSkipped`, remove `visibleArticles` computed property, update `onSkip` call to `viewModel.skip(article: article, context: context)`
- [x] T005 [US1] Remove `@Published var skippedURLsInSession: Set<String>` from `NewsApp/ViewModels/FeedViewModel.swift` and update `FeedViewModelSkipTests.swift` to replace `skippedURLsInSession` assertions with `isSkipped` assertions

**Checkpoint**: User Story 1 独立テスト可能 — `xcodebuild test` で T002 のテストが pass し、`skip()` の永続化が動作すること

---

## Phase 3: User Story 2 — スキップ直後のアンドゥ操作が引き続き機能する (Priority: P2)

**Goal**: `undo()` の `.skipped` ケースで `isSkipped = false` + `context.save()` が呼ばれ、アプリ再起動後もアンドゥが有効

**Independent Test**: スキップ → アンドゥ → アプリ再起動 → 記事がフィードに復活することを確認

### Tests for User Story 2（TDD: 実装前に記述・失敗を確認）⚠️

> **NOTE: T006 を記述して失敗することを確認してから T007 に進む**

- [x] T006 [P] [US2] Write failing TDD tests for undo persistence in `NewsAppTests/Unit/FeedViewModelSkipTests.swift`: add `testUndo_afterSkip_setsIsSkippedFalse()` and `testUndo_afterSkip_savesToContext()`

### Implementation for User Story 2

- [x] T007 [US2] Update `FeedViewModel.undo()` `.skipped` case in `NewsApp/ViewModels/FeedViewModel.swift`: set `article.isSkipped = false` and call `context.save()` (remove `skippedURLsInSession.remove()`)

**Checkpoint**: User Story 1 AND 2 が独立動作 — スキップ永続化とアンドゥ永続化の両方が pass

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: 最終検証とドキュメント更新

- [x] T008 Run `xcodebuild test -scheme NewsApp -destination 'platform=iOS Simulator,name=iPhone Air,OS=26.4.1'` and confirm all tests pass (36 existing + new tests)
- [x] T009 [P] Manual validation per `specs/006-skip-persist/quickstart.md`: run SC-001, SC-002, SC-003 checklist on simulator
- [x] T010 [P] Update `CLAUDE.md` design notes: replace "`skippedURLsInSession` はインメモリのみ" with "`Article.isSkipped: Bool` で永続化（SwiftData）"

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: 依存なし — 即座に開始可能
- **User Story 1 (Phase 2)**: T001 完了後に開始可能
- **User Story 2 (Phase 3)**: T001 完了後に開始可能（US1 に依存しない）
- **Polish (Phase 4)**: US1・US2 両フェーズ完了後

### Within Each User Story

1. テストを記述（TDD）→ 失敗を確認
2. モデル/ViewModel を実装
3. View を更新
4. テストが pass することを確認

### Parallel Opportunities

- T002 と T006 は異なるテストメソッドを追加するため並行記述可能（同一ファイルだが互いに独立）
- T009 と T010 は並行実行可能
- US1（Phase 2）と US2（Phase 3）は T001 完了後に並行実施可能（シングル開発者の場合は P1 優先で順次）

---

## Parallel Example: User Story 1

```bash
# TDD Step 1 — テスト記述（T002）
Task: "Write testSkip_setsIsSkippedTrue() and testSkip_savesToContext() in FeedViewModelSkipTests.swift"

# Confirm tests FAIL before proceeding

# TDD Step 2 — 実装（T003, T004, T005 はこの順で実行）
Task T003: "Update FeedViewModel.skip() in FeedViewModel.swift"
Task T004: "Update FeedView.swift @Query and remove visibleArticles"
Task T005: "Remove skippedURLsInSession, update tests"

# Confirm tests PASS
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: T001 完了（Article.isSkipped 追加）
2. Phase 2: T002 → T003 → T004 → T005 完了
3. **STOP and VALIDATE**: シミュレータでスキップ永続化を確認
4. 問題なければ US2 (Phase 3) へ進む

### Incremental Delivery

1. T001 完了 → 基盤準備
2. T002–T005 完了 → スキップ永続化が動作（MVP）
3. T006–T007 完了 → アンドゥ永続化も動作
4. T008–T010 完了 → 全テスト pass、ドキュメント更新

---

## Notes

- `skip()` のシグネチャ変更（`context: ModelContext` 追加）により、`FeedView.swift` の呼び出し側も更新が必要（T004）
- `skippedURLsInSession` の削除（T005）は T003 完了後に行う
- TDD サイクル: 赤（テスト失敗）→ 緑（テスト pass）→ リファクタ を厳守（Constitution 原則 III）
- `@MainActor` 必須: `context.save()` 呼び出しはすべてメインスレッドで行う（既存の `FeedViewModel` は `@MainActor` 付き）
