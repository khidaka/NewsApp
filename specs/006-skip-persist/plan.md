# Implementation Plan: スキップ記事の永続的非表示

**Branch**: `006-skip-persist` | **Date**: 2026-05-29 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/006-skip-persist/spec.md`

## Summary

スキップ操作で非表示にした記事を、アプリ再起動後も永続的に除外する。`Article` SwiftData モデルに `isSkipped: Bool` フラグを追加し、`FeedView` の `@Query` フィルタを拡張することで実現する。セッション変数 `skippedURLsInSession` は削除し SwiftData に一本化。アンドゥは `context.save()` を使った対称的な実装に更新する。

## Technical Context

**Language/Version**: Swift 5.9+ / iOS 17.0+

**Primary Dependencies**: SwiftUI, SwiftData, FeedKit (SPM)

**Storage**: SwiftData (SQLite) — `Article` モデルに `isSkipped: Bool` フィールドを追加

**Testing**: XCTest — 既存 `FeedViewModelSkipTests` を更新 + 新規永続化テストを追加

**Target Platform**: iOS 17.0+ (シミュレータ: iPhone Air / iOS 26.4.1)

**Project Type**: mobile-app (iOS)

**Performance Goals**: スキップ操作後のカード切替が体感遅延なし。1000件超のスキップ記録でもフィード読み込み遅延なし（`@Query` + SQLite インデックスで対応）

**Constraints**: `@MainActor` 必須（SwiftData の `ModelContext` 操作はメインスレッドのみ）。`Article.isSkipped` への書き込みは `context.save()` を通じてのみ永続化。

**Scale/Scope**: 個人用アプリ、1デバイス、数百〜数千件のスキップ記録を想定

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Content-First Architecture | ✅ PASS | 記事の表示体験を直接改善する変更。データモデルは記事中心 |
| II. Performance & Reliability | ✅ PASS | `@Query` レベルのフィルタリングで SQLite 最適化。UI スレッドブロックなし |
| III. Test-First Development | ✅ PASS | 既存テスト更新 + 新規テスト先行作成（tasks.md で TDD サイクルを定義） |
| IV. User Experience Excellence | ✅ PASS | フィード表示に追加の UI 複雑さなし。スキップ後の即時更新はリアクティブ |
| V. Simplicity & Maintainability | ✅ PASS | 既存 `Article` モデルへのフィールド追加のみ。新規エンティティなし |

**Constitution Check Result**: 全原則 PASS。実装フェーズへ進行可。

## Project Structure

### Documentation (this feature)

```text
specs/006-skip-persist/
├── plan.md              # This file
├── research.md          # 設計決定と代替案
├── data-model.md        # Article モデル変更詳細
├── quickstart.md        # ビルド・手動検証手順
├── checklists/
│   └── requirements.md  # 仕様品質チェックリスト
└── tasks.md             # /speckit-tasks コマンドで生成予定
```

### Source Code (repository root)

```text
NewsApp/
├── Models/
│   └── Article.swift          # isSkipped: Bool フィールド追加
├── ViewModels/
│   └── FeedViewModel.swift    # skip() 更新、undo() 更新、skippedURLsInSession 削除
└── Views/Feed/
    └── FeedView.swift         # @Query フィルタ拡張、visibleArticles プロパティ削除

NewsAppTests/Unit/
└── FeedViewModelSkipTests.swift  # 既存テスト更新 + 永続化テスト追加
```

**Structure Decision**: 単一モバイルアプリ構成を維持。変更は最小限（3ファイル + 1テストファイル）。

## Implementation Phases

### Phase 1: モデル変更とテスト更新

1. `Article.swift` — `isSkipped: Bool = false` フィールドを追加
2. `FeedViewModelSkipTests.swift` — 既存テストを `isSkipped` ベースに更新、永続化テストを追加（TDD: テスト先行）
3. `FeedViewModel.swift` — `skip()` と `undo()` を `isSkipped` + `context.save()` で更新、`skippedURLsInSession` を削除
4. `FeedView.swift` — `@Query` フィルタに `&& !$0.isSkipped` を追加、`visibleArticles` プロパティを削除

### Phase 2: 検証

1. `xcodebuild test` で全テストが pass することを確認
2. quickstart.md の手動検証チェックリストを実施

## Complexity Tracking

> **Constitution Check 違反なし** — 記録不要
