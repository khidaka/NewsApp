---

description: "Task list for スキップアクション"
---

# Tasks: スキップアクション

**Input**: Design documents from `specs/002-skip-action/`

**Prerequisites**: plan.md ✅ | spec.md ✅ | research.md ✅ | data-model.md ✅ | contracts/ ✅

**Tests**: TDD 必須（憲法 III）— T002 のテストを書いて失敗を確認してから実装する。

**Scope**: 既存3ファイルの変更 + テスト1ファイル追加。SwiftData スキーマ変更なし。

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: 並列実行可（異なるファイル、依存関係なし）
- **[Story]**: 対応するユーザーストーリー（US1, US2）

---

## Phase 1: Foundational（全ストーリー共通の基盤）

**Purpose**: `LastAction` enum の定義（US1・US2 両方が依存）

**⚠️ CRITICAL**: このフェーズが完了するまでユーザーストーリーの実装を開始しないこと

- [x] T001 `LastAction` enum を `NewsApp/ViewModels/FeedViewModel.swift` の先頭に追加する（`case swiped(article: Article, kind: SwipeAction)` と `case skipped(article: Article)` の2ケース、`var article: Article` computed property も実装する）

**Checkpoint**: FeedViewModel.swift がコンパイルされる

---

## Phase 2: User Story 1 — 記事をスキップして後回しにする (Priority: P1) 🎯 MVP

**Goal**: スキップ操作でカードをセッション内から除外し、再起動後は再表示候補となる。Undo 対応。

**Independent Test**: 記事をスキップしてアプリを再起動すると、同じ記事が再びスタックに現れる。

### Tests for User Story 1 ⚠️ 先に書いて失敗を確認すること

- [x] T002 [P] [US1] スキップ動作の単体テストを書く `NewsAppTests/Unit/FeedViewModelSkipTests.swift`（skip 後に swipeAction が nil のまま・skippedURLsInSession に URL が追加される・Undo でセッション除外が解除される・personalizationService が呼ばれないことを検証）

### Implementation for User Story 1

- [x] T003 [US1] `FeedViewModel` に `skippedURLsInSession: Set<String>` と `lastAction: LastAction?` を追加し、既存の `lastSwipedArticle: Article?` を削除する `NewsApp/ViewModels/FeedViewModel.swift`
- [x] T004 [US1] `FeedViewModel.skip(article:)` を実装する `NewsApp/ViewModels/FeedViewModel.swift`（`skippedURLsInSession.insert(article.url)`、`lastAction = .skipped(article: article)`、SwiftData 書き込みなし、`PersonalizationService` 呼び出しなし）
- [x] T005 [US1] `FeedViewModel.swipeRight()` と `FeedViewModel.swipeLeft()` を更新する `NewsApp/ViewModels/FeedViewModel.swift`（`lastSwipedArticle =` を `lastAction = .swiped(article:kind:)` に置き換える）
- [x] T006 [US1] `FeedViewModel.undo()` を更新する `NewsApp/ViewModels/FeedViewModel.swift`（`lastAction` が `.skipped` の場合は `skippedURLsInSession.remove(url)` のみ実行、`.swiped` の場合は既存の `swipeAction = nil` 処理、最後に `lastAction = nil`）
- [x] T007 [US1] `FeedView` にスキップ済み記事の除外フィルタを追加する `NewsApp/Views/Feed/FeedView.swift`（`articles.filter { !viewModel.skippedURLsInSession.contains($0.url) }` を返す `visibleArticles` computed property を追加し、`cardStack` で `articles` の代わりに `visibleArticles` を使う）
- [x] T008 [US1] `FeedView` の Undo ボタン表示条件を更新する `NewsApp/Views/Feed/FeedView.swift`（`viewModel.lastSwipedArticle != nil` を `viewModel.lastAction != nil` に置き換える）
- [x] T009 [US1] `FeedView` のカードスタックにスキップコールバックを配線する `NewsApp/Views/Feed/FeedView.swift`（`CardView` の `onSkip` クロージャを追加し `Task { viewModel.skip(article: article) }` を呼ぶ）

**Checkpoint**: テストが通り、上スワイプ以外の方法でスキップが呼べる動作を Simulator で確認できる

---

## Phase 3: User Story 2 — スキップ操作の UI (Priority: P2)

**Goal**: 上スワイプとスキップボタンの2方式でスキップが直感的に実行できる。

**Independent Test**: 上スワイプ・スキップボタンどちらでもカードが消え、右/左スワイプが従来通り機能する。

### Implementation for User Story 2

- [x] T010 [P] [US2] `CardView` に `onSkip: () -> Void` コールバックを追加する `NewsApp/Views/Feed/CardView.swift`（`init` 引数に追加、既存の `onSwipeRight`・`onSwipeLeft` と並列）
- [x] T011 [P] [US2] `CardView` に上スワイプジェスチャーを追加する `NewsApp/Views/Feed/CardView.swift`（既存 `DragGesture.onEnded` 内で `translation.height < -120 && abs(height) > abs(width)` の場合に `flyOut(direction: .up)` → `onSkip()` を呼ぶ、上方向へのフライアウトアニメーション追加）
- [x] T012 [US2] `CardView` 右上にスキップボタンを追加する `NewsApp/Views/Feed/CardView.swift`（`Image(systemName: "forward.end")` を使用、タップ領域 ≥44pt、`.accessibilityLabel("スキップ")` 付き、タップ時に `onSkip()` 呼び出し）

**Checkpoint**: 上スワイプ・ボタン双方でスキップが動作し、quickstart.md の全検証手順をパスする

---

## Phase 4: Polish & 検証

- [ ] T013 [P] 全ユニット・統合テストを実行する（`Cmd+U`）、失敗テストを修正する
- [ ] T014 `quickstart.md` の全検証手順を Simulator または実機で実行して通過を確認する

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: 依存なし — すぐに開始可能
- **US1 (Phase 2)**: Phase 1 完了後 — `LastAction` enum が必要
- **US2 (Phase 3)**: Phase 1 完了後 — US1 と並列実行可能（異なるファイル）
- **Polish (Phase 4)**: US1・US2 完了後

### Within Each User Story

1. T002 のテストを書いて**失敗を確認**する（Red）
2. T003→T009 の順で実装する
3. テストが通ることを確認する（Green）
4. Checkpoint を Simulator で検証してから次のフェーズへ

### Parallel Opportunities

- T002 は T001 完了後すぐ書ける（テストファイルは先に作成可）
- T010・T011 は並列実行可（同じファイルだが独立したコードブロック）
- US2（T010-T012）は US1 の T007-T009 と並列実行可能（FeedView の変更が絡むためやや注意）

---

## Implementation Strategy

### MVP（US1 のみ）

1. T001: `LastAction` enum 追加
2. T002: テスト作成・失敗確認
3. T003〜T009: FeedViewModel + FeedView 実装
4. **STOP and VALIDATE**: テストが通り Simulator でスキップが動作する
5. US2（上スワイプ・ボタン）は後から追加

### 完全実装

1. Phase 1 → Phase 2（US1）→ Phase 3（US2）→ Phase 4（検証）

---

## Notes

- [P] = 並列実行可
- [US*] = ユーザーストーリーへのトレーサビリティ
- SwiftData への変更はゼロ（インメモリのみ）
- `PersonalizationService` は skip で絶対に呼ばない
- `FeedViewModel.skip()` は `context.save()` を呼ばない
