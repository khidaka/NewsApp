---

description: "Task list for スワイプアクションヒント"
---

# Tasks: スワイプアクションヒント

**Input**: Design documents from `specs/003-swipe-action-hint/`

**Prerequisites**: plan.md ✅ | spec.md ✅ | research.md ✅ | data-model.md ✅

**Tests**: TDD 必須（憲法 III）— T002 のテストを先に書いて失敗を確認してから実装する。

**Scope**: `CardView.swift` 1ファイルのみ変更。SwiftData・ViewModel 変更なし。

---

## Phase 1: Foundational（全ストーリー共通の基盤）

**Purpose**: `HintDirection` enum の定義（US1・US2 両方が依存）

- [x] T001 `HintDirection` private enum を `NewsApp/Views/Feed/CardView.swift` 内に追加する（`case right`・`case left`・`case up` の3ケース）

**Checkpoint**: CardView.swift がコンパイルされる

---

## Phase 2: User Story 1 — スワイプ中にアクションの種類がわかる (Priority: P1) 🎯 MVP

**Goal**: ドラッグ中に対応するアクションのバッジが表示され、距離に応じて不透明度が変化する。

**Independent Test**: 右・左・上の各方向にドラッグすると対応する色のバッジが出ることを Simulator で確認できる。

### Tests for User Story 1 ⚠️ 先に書いて失敗を確認すること

- [x] T002 [P] [US1] `hintOpacity` 計算ロジックの単体テストを書く `NewsAppTests/Unit/CardViewHintTests.swift`（5pt 未満は opacity=0、hThreshold×0.5 以上は opacity=1.0、中間値の線形スケールを検証）

### Implementation for User Story 1

- [x] T003 [US1] `@State private var hintDirection: HintDirection?` と `private var hintOpacity: Double` computed property を `CardView.swift` に追加する（`hintOpacity` は `min(1.0, abs(offset) / (threshold * 0.5))` を方向に応じて計算）
- [x] T004 [US1] `DragGesture.onChanged` を更新して `hintDirection` をリアルタイムに設定する `NewsApp/Views/Feed/CardView.swift`（ドラッグ距離 5pt 未満は `nil`、以降は縦横優先判定に応じて `.right`/`.left`/`.up` を設定）
- [x] T005 [US1] `DragGesture.onEnded` と `flyOut()` で `hintDirection = nil` にリセットする `NewsApp/Views/Feed/CardView.swift`（キャンセル・完了を問わずヒントをクリア）
- [x] T006 [US1] `ActionHintView` private struct を `CardView.swift` 内に実装する（`HintDirection` と `opacity: Double` を受け取り、方向に応じたアイコン・ラベル・色の Capsule バッジを描画する。右=緑`square.and.arrow.up`「共有」、左=赤`hand.thumbsdown`「興味なし」、上=グレー`forward.end`「スキップ」）
- [x] T007 [US1] `CardView` の body ZStack 最上層に `ActionHintView` を重ねる `NewsApp/Views/Feed/CardView.swift`（`hintDirection` が非 nil のときのみ表示、配置は右→`.topLeading`・左→`.topTrailing`・上→`.top`）

**Checkpoint**: テストが通り、3方向のバッジが Simulator で確認できる

---

## Phase 3: User Story 2 — ヒントの視認性と強調 (Priority: P2)

**Goal**: 閾値に近づくほどバッジが濃くなる。

**Independent Test**: 閾値 50% 未満で薄く、75% 以上で完全不透明になることを Simulator で確認できる。

- [ ] T008 [US2] quickstart.md の US2 検証手順（ドラッグ距離と不透明度変化の確認）を Simulator で実行し、`hintOpacity` 計算式が SC-001・P2 のシナリオを満たすことを確認する `NewsApp/Views/Feed/CardView.swift`（不十分なら `hThreshold * 0.5` の係数を調整する）

**Checkpoint**: P2 シナリオが視覚的に確認できる

---

## Phase 4: Polish & 検証

- [ ] T009 [P] 全ユニット・統合テストを実行する（`Cmd+U`）、失敗テストを修正する
- [ ] T010 quickstart.md の「既存動作の非回帰確認」手順を実行し、右/左/上スワイプ完了・Undo が従来通り動作することを確認する

---

## Dependencies & Execution Order

- **Foundational (Phase 1)**: 依存なし
- **US1 (Phase 2)**: Phase 1 完了後
- **US2 (Phase 3)**: US1 の T003 完了後（`hintOpacity` 計算式が必要）
- **Polish (Phase 4)**: US1・US2 完了後

### Parallel Opportunities

- T002 は T001 完了後すぐ書ける（テストファイルは先に作成可）
- T006・T007 は T003〜T005 と並列実行可（ZStack 追加は独立した変更ブロック）

---

## Implementation Strategy

### MVP（US1 のみ）

1. T001: `HintDirection` enum 追加
2. T002: テスト作成・失敗確認
3. T003〜T007: CardView 実装
4. **STOP and VALIDATE**: Simulator で3方向のバッジが動作する
5. T008（US2）は動作確認後に追加

---

## Notes

- `ActionHintView` は `CardView.swift` 内 private struct（独立ファイル不要）
- `hintOpacity` は `@State` ではなく computed property（SwiftUI が自動的に再描画）
- 5pt 未満は nil にすることで誤タッチ時にバッジが瞬滅しない
