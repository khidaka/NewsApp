# Implementation Plan: 利用統計に基づくおすすめソースの自動調整

**Branch**: `007-smart-source-suggestions` | **Date**: 2026-05-29 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/007-smart-source-suggestions/spec.md`

## Summary

ソース追加シートのおすすめリストを、ユーザーの利用傾向に合わせて自動で並び替える。`SuggestedSource` に代表キーワード群を追加し、既存 `PersonalizationService` が `InterestSignal` から生成するキーワード重みマップと突き合わせてスコアを算出。スコア降順（同点時は静的定義順）でソートする。スコアリングは `SuggestedSources` の純粋関数として実装し、シート表示時に毎回再計算する。

## Technical Context

**Language/Version**: Swift 5.9+ / iOS 17.0+

**Primary Dependencies**: SwiftUI, SwiftData, NaturalLanguage（既存のキーワード抽出で使用）

**Storage**: 永続化の追加なし。`InterestSignal`（既存）を `@Query` で読み出し、スコアは表示時に算出（非永続）

**Testing**: XCTest — `SuggestedSources.ranked(...)` の純粋関数ユニットテストを新規追加

**Target Platform**: iOS 17.0+（シミュレータ: iPhone Air / iOS 26.4.1）

**Project Type**: mobile-app (iOS)

**Performance Goals**: シート表示時のスコア計算は 7 ソース程度で体感遅延なし（SC-003）

**Constraints**: ローカルデータのみ（リモート通信・手動編集なし）。スコアリングは I/O を持たない純粋関数とし、SwiftData アクセスは View の `@Query` に委ねる

**Scale/Scope**: おすすめ 7 件固定、シグナル数は利用に応じて増加（重みマップ集計は既存実装で対応済み）

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Content-First Architecture | ✅ PASS | ソース発見体験を直接改善。データは記事・ソース・利用行動中心 |
| II. Performance & Reliability | ✅ PASS | 軽量な純粋関数。UI ブロックなし。リモート依存なしで信頼性高い |
| III. Test-First Development | ✅ PASS | `ranked(...)` は純粋関数で TDD しやすい。テスト先行（tasks.md で定義） |
| IV. User Experience Excellence | ✅ PASS | 既存の追加シート UI を踏襲。並び順のみ動的化、新規 UI 要素なし |
| V. Simplicity & Maintainability | ✅ PASS | 既存 `PersonalizationService` のロジックを再利用。`SuggestedSource` への配列1つ追加のみ |

**Constitution Check Result**: 全原則 PASS。実装フェーズへ進行可。

## Project Structure

### Documentation (this feature)

```text
specs/007-smart-source-suggestions/
├── plan.md              # This file
├── research.md          # 設計決定（スコアリング・責務配置・同点処理）
├── data-model.md        # SuggestedSource.keywords とランキングアルゴリズム
├── quickstart.md        # ビルド・手動検証手順
├── checklists/
│   └── requirements.md  # 仕様品質チェックリスト
└── tasks.md             # /speckit-tasks で生成予定
```

### Source Code (repository root)

```text
NewsApp/
├── Models/
│   └── SuggestedSource.swift   # keywords: [String] 追加、ranked(excluding:signals:) 追加
└── Views/Settings/
    └── SourceListView.swift    # filteredSuggestions を ranked(...) 呼び出しに変更、@Query で InterestSignal を取得

NewsAppTests/Unit/
└── SuggestedSourcesTests.swift # ranked(...) のスコアリング・ソート・同点処理テストを追加
```

**Structure Decision**: 単一モバイルアプリ構成を維持。変更は最小限（2ファイル + 1テストファイル）。新規 SwiftData モデル・永続化なし。

## Implementation Phases

### Phase 1: モデル拡張とランキングロジック（TDD）

1. `SuggestedSourcesTests.swift` — `ranked(excluding:signals:)` のテストを先行作成（新規ユーザー＝定義順、傾向反映、同点＝定義順、追加済み除外）
2. `SuggestedSource.swift` — `keywords: [String]` フィールドを追加し、7 ソースに代表キーワードを定義
3. `SuggestedSource.swift` — `ranked(excluding:signals:)` 純粋関数を実装（重み集計→スコア→安定ソート）

### Phase 2: View 統合

1. `SourceListView.swift` — `@Query private var signals: [InterestSignal]` を追加
2. `SourceListView.swift` — `filteredSuggestions` を `SuggestedSources.ranked(excluding:signals:)` 呼び出しに変更

### Phase 3: 検証

1. `xcodebuild test` で全テスト pass を確認
2. quickstart.md の手動検証チェックリストを実施

## Complexity Tracking

> **Constitution Check 違反なし** — 記録不要
