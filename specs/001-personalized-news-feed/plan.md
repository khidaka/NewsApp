# Implementation Plan: パーソナライズドニュースフィード

**Branch**: `001-personalized-news-feed` | **Date**: 2026-05-29 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-personalized-news-feed/spec.md`

## Summary

日本語ニュースサイトの RSS/Atom フィードを収集し、SwiftUI のスワイプカード UI で表示する個人用 iOS アプリ。右スワイプで Readwise Reader に記事を共有し、左スワイプで「興味なし」を記録する。シェア履歴・興味なし履歴・Obsidian Vault のノート内容を組み合わせたキーワードスコアリングによって表示優先度を決定する。技術アプローチ: Swift/SwiftUI + SwiftData + FeedKit (SPM) + Apple NaturalLanguage framework。

## Technical Context

**Language/Version**: Swift 5.9+ / iOS 17.0+

**Primary Dependencies**:
- SwiftUI（ネイティブ — UI）
- SwiftData（ネイティブ — 永続化）
- FeedKit via SPM（RSS 2.0 / Atom 1.0 パーシング）
- NaturalLanguage framework（ネイティブ — 日本語キーワード抽出）
- BGTaskScheduler（ネイティブ — バックグラウンドフェッチ）

**Storage**: SwiftData（Article・NewsSource・InterestSignal）、UserDefaults（Obsidian Vault bookmark・設定値）

**Testing**: XCTest（ユニット・統合テスト）、XCUITest（UI テスト）

**Target Platform**: iOS 17.0+（単一デバイス・個人用）

**Project Type**: Mobile app（iOS native）

**Performance Goals**:
- アプリ起動 → 最初のカード表示: ≤ 3秒（SC-001）
- 右スワイプ → 共有シート表示: ≤ 1秒（SC-002）
- バックグラウンドフェッチ: ≤ 30秒（iOS 上限内）

**Constraints**:
- ローカルのみ（サーバーなし）
- バックグラウンドフェッチは iOS BGTaskScheduler 制約内（実行保証なし）
- Obsidian Vault アクセスは security-scoped URL bookmark 経由
- 外部依存は FeedKit のみ（憲法 V: 簡潔さ）

**Scale/Scope**: 1ユーザー・1デバイス・最大20ソース・最大50件/フェッチ・最大350件保持

## Constitution Check

*GATE: Phase 0 研究前に確認。Phase 1 設計後に再確認。*

| 原則 | 状態 | 根拠 |
|------|------|------|
| I. コンテンツファースト | ✅ PASS | 全機能がニュース閲覧・共有に直結する |
| II. パフォーマンス・信頼性 | ✅ PASS | SC-001(3s)・SC-002(1s) 定義済み。ソース障害時は部分表示（FR-015適用）|
| III. テストファースト（NON-NEGOTIABLE） | ⚠ GATE | タスク実装前にテストを書き、失敗確認後に実装すること |
| IV. ユーザー体験の卓越性 | ✅ PASS | SwiftUI デフォルトアクセシビリティ対応。カード表示は起動後3秒以内 |
| V. 簡潔さと保守性 | ✅ PASS | 外部依存1件のみ（FeedKit）。MVVM + SwiftData で最小構成 |

**Phase 1 再確認（設計後）**: 全原則 PASS — アーキテクチャは MVVM 単一プロジェクト、不要な抽象化なし。

## Project Structure

### Documentation (this feature)

```text
specs/001-personalized-news-feed/
├── plan.md              # このファイル
├── research.md          # Phase 0 出力（技術選定の根拠）
├── data-model.md        # Phase 1 出力（SwiftData モデル定義）
├── quickstart.md        # Phase 1 出力（ビルド・検証手順）
├── contracts/
│   └── service-interfaces.md   # Phase 1 出力（サービス境界定義）
└── tasks.md             # Phase 2 出力（/speckit-tasks コマンドが生成）
```

### Source Code (repository root)

```text
NewsApp/
├── NewsApp.xcodeproj/
├── NewsApp/
│   ├── App/
│   │   ├── NewsAppApp.swift          # エントリポイント・SwiftData container
│   │   └── ContentView.swift         # ルートビュー（TabView）
│   ├── Models/                        # SwiftData @Model
│   │   ├── Article.swift
│   │   ├── NewsSource.swift
│   │   └── InterestSignal.swift
│   ├── ViewModels/
│   │   ├── FeedViewModel.swift        # メインフィード状態管理
│   │   └── SettingsViewModel.swift    # ソース管理・Vault 設定
│   ├── Views/
│   │   ├── Feed/
│   │   │   ├── FeedView.swift         # スワイプカードスタック
│   │   │   └── CardView.swift         # 1枚のカード
│   │   └── Settings/
│   │       ├── SettingsView.swift     # 設定画面ルート
│   │       ├── SourceListView.swift   # ソース一覧・追加・削除
│   │       └── VaultPickerView.swift  # Obsidian Vault 選択
│   ├── Services/
│   │   ├── NewsCollectorService.swift
│   │   ├── RSSParserService.swift
│   │   ├── PersonalizationService.swift
│   │   └── ObsidianReaderService.swift
│   └── Resources/
│       └── Info.plist                 # BGTaskSchedulerPermittedIdentifiers 含む
└── NewsAppTests/
    ├── Unit/
    │   ├── PersonalizationServiceTests.swift
    │   ├── RSSParserServiceTests.swift
    │   └── ObsidianReaderServiceTests.swift
    └── Integration/
        └── NewsCollectorIntegrationTests.swift
```

**Structure Decision**: iOS mobile app（Option 3 相当）。単一 Xcode プロジェクト。サーバーサイドなし。テストターゲットは別ターゲット（`NewsAppTests`）として同一プロジェクト内に配置。

## Complexity Tracking

> Phase 0/1 で憲法違反なし。記録事項なし。
