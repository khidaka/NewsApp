# Implementation Plan: スワイプアクションヒント

**Branch**: `003-swipe-action-hint` | **Date**: 2026-05-29 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/003-swipe-action-hint/spec.md`

## Summary

スワイプ中に現在の操作をバッジ形式でリアルタイム表示する UI 機能。右スワイプ中は緑の「共有」、
左スワイプ中は赤の「興味なし」、上スワイプ中はグレーの「スキップ」バッジがカードの端に出現し、
ドラッグ距離に応じて不透明度が変化する。変更対象は `CardView.swift` 1ファイルのみ。

## Technical Context

**Language/Version**: Swift 5.9+ / iOS 17.0+（既存と同じ）

**Primary Dependencies**: SwiftUI（既存）— 新規依存なし

**Storage**: なし（表示専用）

**Testing**: XCTest — `hintOpacity` 計算ロジックの単体テスト

**Target Platform**: iOS 17.0+

**Project Type**: 既存 iOS アプリへの UI 機能追加

**Performance Goals**: ドラッグ開始から 100ms 以内にヒントが表示される（SC-001）

**Constraints**:
- 変更ファイルは `CardView.swift` 1ファイルのみ
- SwiftData 変更なし、ViewModel 変更なし
- 既存スワイプ動作（flyOut・onSwipeRight/Left/Skip）は変更しない

**Scale/Scope**: 単一ファイルの UI 拡張

## Constitution Check

| 原則 | 状態 | 根拠 |
|------|------|------|
| I. コンテンツファースト | ✅ PASS | ヒントはコンテンツを覆わず、操作性向上に直結 |
| II. パフォーマンス・信頼性 | ✅ PASS | 純粋な SwiftUI `@State` 計算、パフォーマンス影響なし |
| III. テストファースト | ⚠ GATE | `hintOpacity` 計算ロジックのテストを先に書く |
| IV. ユーザー体験の卓越性 | ✅ PASS | 操作前フィードバックは UX 標準パターン |
| V. 簡潔さと保守性 | ✅ PASS | 変更1ファイル、新規追加は private struct のみ |

## Project Structure

### Documentation (this feature)

```text
specs/003-swipe-action-hint/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
└── tasks.md     # /speckit-tasks が生成
```

### Source Code（変更対象のみ）

```text
NewsApp/Views/Feed/CardView.swift          # HintDirection enum・ActionHintView 追加、DragGesture 更新

NewsAppTests/Unit/CardViewHintTests.swift  # hintOpacity 計算ロジックのテスト
```

**Structure Decision**: 既存単一プロジェクト維持。`ActionHintView` は `CardView` 内 private struct として実装（独立ファイル不要）。

## Complexity Tracking

> 憲法違反なし。記録事項なし。
