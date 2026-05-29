# Implementation Plan: スキップアクション

**Branch**: `002-skip-action` | **Date**: 2026-05-29 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/002-skip-action/spec.md`

## Summary

既存のスワイプカード UI に「スキップ」操作を追加する。上スワイプまたは専用ボタンで記事を
セッション内から除外するが、SwiftData には書き込まず、パーソナライズアルゴリズムにも影響
を与えない。アプリ再起動後は未スワイプの記事として扱われ再表示の候補となる。
変更対象は `FeedViewModel`・`CardView`・`FeedView` の3ファイルのみ。

## Technical Context

**Language/Version**: Swift 5.9+ / iOS 17.0+（既存プロジェクトに追従）

**Primary Dependencies**: SwiftUI（既存）、SwiftData（既存）— 新規依存なし

**Storage**: インメモリのみ（`Set<String>` — スキップ URL セット）。SwiftData スキーマ変更なし

**Testing**: XCTest（既存テストターゲット `NewsAppTests`）

**Target Platform**: iOS 17.0+（既存と同じ）

**Project Type**: 既存 iOS アプリへの機能追加

**Performance Goals**: スキップアニメーション完了 ≤0.5秒（SC-001）

**Constraints**:
- SwiftData への書き込みは一切しない
- `PersonalizationService.recordSignal()` を呼ばない
- 変更ファイルは最小限（3ファイル + テスト1ファイル）

**Scale/Scope**: 既存機能の拡張。新規ファイル不要

## Constitution Check

| 原則 | 状態 | 根拠 |
|------|------|------|
| I. コンテンツファースト | ✅ PASS | スキップはコンテンツ閲覧体験の改善 |
| II. パフォーマンス・信頼性 | ✅ PASS | インメモリ操作のみ、DB 書き込みなし |
| III. テストファースト（NON-NEGOTIABLE） | ⚠ GATE | テストを先に書いて失敗を確認してから実装する |
| IV. ユーザー体験の卓越性 | ✅ PASS | 上スワイプ＋ボタンの2方式、スキップボタン ≥44pt |
| V. 簡潔さと保守性 | ✅ PASS | 新規ファイルなし、最小変更 |

## Project Structure

### Documentation (this feature)

```text
specs/002-skip-action/
├── plan.md              # このファイル
├── research.md          # Phase 0 出力
├── data-model.md        # Phase 1 出力（スキーマ変更なし、ViewModel 変更のみ）
├── quickstart.md        # Phase 1 出力
├── contracts/
│   └── feedviewmodel-interface.md
└── tasks.md             # Phase 2 出力（/speckit-tasks が生成）
```

### Source Code（変更対象のみ）

```text
NewsApp/ViewModels/FeedViewModel.swift   # lastAction enum 追加、skip() 追加、undo() 拡張
NewsApp/Views/Feed/CardView.swift        # 上スワイプ追加、スキップボタン追加
NewsApp/Views/Feed/FeedView.swift        # visibleArticles フィルタ、スキップ配線

NewsAppTests/Unit/FeedViewModelSkipTests.swift   # 新規テストファイル（TDD）
```

**Structure Decision**: 既存の単一プロジェクト構成を維持。新規ディレクトリ不要。

## Complexity Tracking

> 憲法違反なし。記録事項なし。
