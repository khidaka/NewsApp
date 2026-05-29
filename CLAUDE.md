<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
at specs/003-swipe-action-hint/plan.md
<!-- SPECKIT END -->

## プロジェクト概要

個人用 iOS ニュースアグリゲータアプリ。Swift/SwiftUI + SwiftData、iOS 17.0+。

## 技術スタック

- **言語**: Swift 5.9+ / iOS 17.0+
- **UI**: SwiftUI + SwiftData
- **外部依存**: FeedKit (SPM) — RSS 2.0 / Atom パーシング
- **プロジェクト生成**: xcodegen（`project.yml` → `NewsApp.xcodeproj`）
- **ビルドコマンド**: `xcodegen generate && xcodebuild -scheme NewsApp -destination 'platform=iOS Simulator,name=iPhone Air,OS=26.4.1' build`
- **テストコマンド**: `xcodebuild test -scheme NewsApp -destination 'platform=iOS Simulator,name=iPhone Air,OS=26.4.1'`

## 実装済み機能

| ブランチ | 機能 | 主な変更ファイル |
|---------|------|----------------|
| `001-personalized-news-feed` | RSS収集・スワイプカード・パーソナライズ（3シグナル）・Obsidian Vault 連携 | 全ソース初期実装 |
| `002-skip-action` | スキップ操作（セッション限定・SwiftData 書き込みなし） | `FeedViewModel.swift`・`CardView.swift`・`FeedView.swift` |
| `003-swipe-action-hint` | スワイプ中アクションヒントバッジ（右=緑・左=赤・上=グレー、距離連動不透明度） | `CardView.swift` のみ |
| `004-app-icon` | アプリアイコン（黒背景＋3本白角丸線） | `Assets.xcassets/AppIcon.appiconset/` |

全ブランチは `main` にマージ済み。GitHub: https://github.com/khidaka/NewsApp

## 重要な設計メモ

- **スキップ**: `FeedViewModel.skippedURLsInSession: Set<String>` はインメモリのみ（再起動でリセット）
- **Undo**: `LastAction` enum（`.swiped` / `.skipped`）で型安全に管理
- **パーソナライズ**: `shared:+2`・`notInterested:-3`・`Obsidian:+1` の加重スコアリング
- **Obsidian Vault**: 起動時のみスキャン、security-scoped URL bookmark で iCloud Drive アクセス
- **BGTaskScheduler**: `com.newsapp.refresh`（1時間ごと）

## テスト状況（2026-05-29）

28テスト全合格（Unit 25件 + Integration 3件）。

## 次のフィーチャー追加方法

```bash
/speckit-specify <機能の説明>
# → /speckit-plan → /speckit-tasks → /speckit-implement
```
