<!-- SPECKIT START -->
進行中フィーチャーのプランは specs/006-skip-persist/plan.md（ブランチ: 006-skip-persist）。
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
| `005-news-source-suggestions` | ソース追加シート上部に静的おすすめリスト（7件）・ワンタップ追加・重複防止・シート継続表示 | `NewsApp/Models/SuggestedSource.swift`（新規）・`SourceListView.swift` |

全ブランチは `main` にマージ済み。GitHub: https://github.com/khidaka/NewsApp

## 重要な設計メモ

- **スキップ**: `Article.isSkipped: Bool` で SwiftData に永続化（再起動後も非表示を維持）。`FeedView` の `@Query` フィルタ（`!$0.isSkipped`）で除外。
- **Undo**: `LastAction` enum（`.swiped` / `.skipped`）で型安全に管理
- **パーソナライズ**: `shared:+2`・`notInterested:-3`・`Obsidian:+1` の加重スコアリング
- **Obsidian Vault**: 起動時のみスキャン、security-scoped URL bookmark で iCloud Drive アクセス
- **BGTaskScheduler**: `com.newsapp.refresh`（1時間ごと）
- **スレッド安全**: `PersonalizationService.recordSignal` は `@MainActor` 必須。`ModelContext` をオフメインスレッドで操作すると SwiftData がクラッシュする（iOS 17+）。

## テスト状況（2026-05-29）

36テスト全合格（Unit 33件 + Integration 3件）。
実機: iPhone Air / iOS 26.5。

## 次のフィーチャー追加方法

```bash
/speckit-specify <機能の説明>
# → /speckit-plan → /speckit-tasks → /speckit-implement
```
