---

description: "Task list for パーソナライズドニュースフィード"
---

# Tasks: パーソナライズドニュースフィード

**Input**: Design documents from `specs/001-personalized-news-feed/`

**Prerequisites**: plan.md ✅ | spec.md ✅ | research.md ✅ | data-model.md ✅ | contracts/ ✅

**Tests**: TDD 必須（憲法 III. テストファーストは NON-NEGOTIABLE）— 各ユーザーストーリーに失敗テストを先に書き、失敗を確認してから実装する。

**Organization**: ユーザーストーリー別にフェーズを分けて独立実装・テストを可能にする。

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: 並列実行可（異なるファイル、依存関係なし）
- **[Story]**: 対応するユーザーストーリー（US1, US2, US3）

---

## Phase 1: Setup（プロジェクト初期化）

**Purpose**: Xcode プロジェクト作成と依存関係設定

- [ ] T001 Xcode プロジェクト `NewsApp.xcodeproj` を作成し、iOS 17.0 ターゲット・SwiftUI ライフサイクルで初期化する
- [ ] T002 Swift Package Manager で FeedKit を追加する（`https://github.com/nmdias/FeedKit`）
- [ ] T003 [P] `NewsApp/Resources/Info.plist` に `BGTaskSchedulerPermittedIdentifiers` を追加する（値: `com.newsapp.refresh`）
- [ ] T004 [P] `NewsAppTests` テストターゲットを作成し `NewsAppTests/Unit/` と `NewsAppTests/Integration/` ディレクトリ構造を作る

---

## Phase 2: Foundational（全ストーリー共通の基盤）

**Purpose**: SwiftData モデル・プロトコル定義・アプリ骨格（ユーザーストーリー実装のブロッカー）

**⚠️ CRITICAL**: このフェーズが完了するまでユーザーストーリーの実装を開始しないこと

- [ ] T005 SwiftData `@Model` で `Article` を実装する `NewsApp/Models/Article.swift`（フィールド: id, url[@Attribute(.unique)], title, summary, sourceName, sourceURL, fetchedAt, swipeAction?, score）
- [ ] T006 [P] SwiftData `@Model` で `NewsSource` を実装する `NewsApp/Models/NewsSource.swift`（フィールド: id, name, feedURL[@Attribute(.unique)], isEnabled, addedAt）
- [ ] T007 [P] SwiftData `@Model` で `InterestSignal` を実装する `NewsApp/Models/InterestSignal.swift`（フィールド: id, keyword, signalType, sourceName, recordedAt、列挙型 SignalType・SwipeAction も定義）
- [ ] T008 SwiftData `ModelContainer` を `NewsApp/App/NewsAppApp.swift` に設定し、`.modelContainer(for:)` で Article・NewsSource・InterestSignal を登録する
- [ ] T009 `NewsApp/App/ContentView.swift` に `TabView`（フィードタブ・設定タブ）のルートナビゲーションを実装する
- [ ] T010 [P] `NewsCollectorServiceProtocol`・`RSSParserServiceProtocol` を `NewsApp/Services/NewsCollectorService.swift` と `NewsApp/Services/RSSParserService.swift` に定義する（contracts/service-interfaces.md の仕様通り）
- [ ] T011 [P] `PersonalizationServiceProtocol` を `NewsApp/Services/PersonalizationService.swift` に定義する
- [ ] T012 [P] `ObsidianReaderServiceProtocol` と `ObsidianContext` struct を `NewsApp/Services/ObsidianReaderService.swift` に定義する

**Checkpoint**: SwiftData モデルがコンパイルされ、アプリが起動してタブ画面が表示される

---

## Phase 3: User Story 1 — スワイプでニュースを閲覧・共有する (Priority: P1) 🎯 MVP

**Goal**: RSS フィードから記事を取得し、スワイプカードで閲覧・右スワイプ共有・左スワイプ興味なし・Undo が動作する

**Independent Test**: アプリを開き、カードが表示され、右スワイプで共有シートが起動し、左スワイプでカードが消えることを確認できる

### Tests for User Story 1 ⚠️ 先に書いて失敗を確認すること

- [ ] T013 [P] [US1] `RSSParserService` の単体テストを書く `NewsAppTests/Unit/RSSParserServiceTests.swift`（RSS 2.0 パース・Atom パース・空 summary 補完・無効 URL スキップを検証）
- [ ] T014 [P] [US1] `NewsCollectorService` の統合テストを書く `NewsAppTests/Integration/NewsCollectorIntegrationTests.swift`（URL 重複除去・50件上限・部分失敗継続を検証）

### Implementation for User Story 1

- [ ] T015 [US1] `RSSParserService` を実装する `NewsApp/Services/RSSParserService.swift`（FeedKit を使い RSS 2.0 / Atom を `RawArticle` 配列に変換、T013 を通す）
- [ ] T016 [US1] `NewsCollectorService.fetchAll()` を実装する `NewsApp/Services/NewsCollectorService.swift`（全有効ソースを並列フェッチ・URL 重複除去・スワイプ済み除外・50件制限・部分失敗継続、T014 を通す）
- [ ] T017 [US1] `FeedViewModel` を実装する `NewsApp/ViewModels/FeedViewModel.swift`（`@Query` で未スワイプ記事をスコア降順取得、isLoading・errorMessage・lastSwipedArticle 状態管理）
- [ ] T018 [P] [US1] `CardView` を実装する `NewsApp/Views/Feed/CardView.swift`（タイトル・概要表示・`DragGesture` で水平スワイプ、オフセット ≥ 画面幅×0.4 でアクション確定、spring アニメーション）
- [ ] T019 [US1] `FeedView` を実装する `NewsApp/Views/Feed/FeedView.swift`（カードスタック、リロードボタン、空状態・ローディング・エラー表示）
- [ ] T020 [P] [US1] `ShareSheet.swift` を実装する `NewsApp/Views/Feed/ShareSheet.swift`（`UIActivityViewController` を `UIViewControllerRepresentable` でラップ、URL と title を `activityItems` に渡す）
- [ ] T021a [US1] `PersonalizationService` のスタブ実装を `NewsApp/Services/PersonalizationService.swift` に追加する（`recordSignal` を no-op、`score` は受け取った配列をそのまま返す）— US3（T032-T033）で本実装に置き換える
- [ ] T021 [US1] 右スワイプ → 共有シート起動を `FeedViewModel.swift` と `FeedView.swift` に配線する（`PersonalizationService.recordSignal(.shared)` も呼ぶ）
- [ ] T022 [US1] 左スワイプ → 興味なし記録を `FeedViewModel.swift` に実装する（`Article.swipeAction = .notInterested` 更新、`PersonalizationService.recordSignal(.notInterested)` 呼び出し）
- [ ] T023 [US1] Undo（直前スワイプ取り消し）を実装する:
  - `FeedViewModel.swift`: `lastSwipedArticle` の `swipeAction` を `nil` に戻してスタック先頭に復元するロジックを追加する
  - `FeedView.swift`: Undo ボタン（`lastSwipedArticle != nil` のときのみ表示）を追加する
- [ ] T024 [US1] 手動リロードを `FeedViewModel.swift` と `FeedView.swift` に実装する（リロードボタン → `NewsCollectorService.fetchAll()` → 新記事をスタック先頭に追加）
- [ ] T025 [US1] バックグラウンドフェッチを `NewsApp/App/NewsAppApp.swift` に実装する（`BGTaskScheduler` に `com.newsapp.refresh` を登録・タスク完了後に次回スケジュール、`NewsCollectorService.fetchAll()` を呼ぶ）

**Checkpoint**: User Story 1 が独立してビルド・動作し、quickstart.md の P1 検証手順をすべてパスする

---

## Phase 4: User Story 2 — ニュースソースを管理する (Priority: P2)

**Goal**: 設定画面からニュースソースの追加・削除ができ、次回リロードに反映される

**Independent Test**: 設定でソースを1件追加しリロードすると、そのソースの記事が表示される

### Tests for User Story 2 ⚠️ 先に書いて失敗を確認すること

- [ ] T026 [P] [US2] `SettingsViewModel` の単体テストを書く `NewsAppTests/Unit/SettingsViewModelTests.swift`（ソース追加・削除・無効 URL バリデーションエラーを検証）

### Implementation for User Story 2

- [ ] T027 [US2] `SettingsViewModel` を実装する `NewsApp/ViewModels/SettingsViewModel.swift`（NewsSource の追加・削除・一覧取得、RSS URL 形式バリデーション、T026 を通す）
- [ ] T028 [P] [US2] `SourceListView` を実装する `NewsApp/Views/Settings/SourceListView.swift`（ソース一覧表示、追加シート、スワイプ削除）
- [ ] T029 [US2] `SettingsView` を実装する `NewsApp/Views/Settings/SettingsView.swift`（SourceListView へのナビゲーション・VaultPickerView へのリンク）

**Checkpoint**: User Story 2 が独立して動作し、quickstart.md の P2 検証手順をパスする

---

## Phase 5: User Story 3 — パーソナライズされたニュースが表示される (Priority: P3)

**Goal**: 3シグナル（シェア履歴・興味なし履歴・Obsidian Vault）でスコアリングし、興味に合った記事が上位に表示される

**Independent Test**: 特定トピックを10回以上「興味なし」にした後、リロードするとそのトピックの記事が下位になる

### Tests for User Story 3 ⚠️ 先に書いて失敗を確認すること

- [ ] T030 [P] [US3] `PersonalizationService` の単体テストを書く `NewsAppTests/Unit/PersonalizationServiceTests.swift`（スコア計算・重み付け・Obsidian なし時の動作・スコア降順ソートを検証）
- [ ] T031 [P] [US3] `ObsidianReaderService` の単体テストを書く `NewsAppTests/Unit/ObsidianReaderServiceTests.swift`（Markdown パース・frontmatter スキップ・短トークン除外・キーワード頻度集計を検証）

### Implementation for User Story 3

- [ ] T032 [US3] `PersonalizationService.score()` を実装する `NewsApp/Services/PersonalizationService.swift`（InterestSignal からキーワード辞書構築、タイトル＋概要でスコア計算、Obsidian +1 / shared +2 / notInterested -3、スコア降順ソート、T030 を通す）
- [ ] T033 [US3] `PersonalizationService.recordSignal()` を実装する `NewsApp/Services/PersonalizationService.swift`（スワイプ時にタイトル＋概要から `NLTokenizer` で名詞抽出、`InterestSignal` を SwiftData に保存）
- [ ] T034 [US3] `ObsidianReaderService.extractKeywords()` を実装する `NewsApp/Services/ObsidianReaderService.swift`（security-scoped bookmark 解除・全 .md ファイル読み取り・frontmatter スキップ・`NLTokenizer` で名詞抽出・頻度マップ返却、T031 を通す）
- [ ] T035 [US3] `ObsidianReaderService.saveVaultBookmark()` を実装する `NewsApp/Services/ObsidianReaderService.swift`（security-scoped URL → bookmark データ → UserDefaults 保存）
- [ ] T036 [P] [US3] `VaultPickerView` を実装する `NewsApp/Views/Settings/VaultPickerView.swift`（`UIDocumentPickerViewController` でフォルダ選択、`ObsidianReaderService.saveVaultBookmark()` 呼び出し、選択パス表示）
- [ ] T037 [US3] アプリ起動時に Obsidian Vault スキャンを実行する `NewsApp/App/NewsAppApp.swift`（UserDefaults から bookmark 読み取り → `ObsidianReaderService.extractKeywords()` → `ObsidianContext` を environment に注入）
- [ ] T038 [US3] `NewsCollectorService.fetchAll()` に `PersonalizationService.score()` を統合する `NewsApp/Services/NewsCollectorService.swift`（取得後スコアリング → 上位50件選択 → スタック先頭に追加）
- [ ] T039 [US3] 7日経過した `Article` と `InterestSignal` の定期クリーンアップを `NewsApp/App/NewsAppApp.swift` に実装する（起動時 or バックグラウンドタスク完了時に `fetchedAt < now - 7days` の記録を削除）

**Checkpoint**: User Story 3 が独立して動作し、quickstart.md の P3 検証手順をパスする

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: 全ストーリーにまたがる品質改善

- [ ] T040 [P] `FeedView.swift` に空状態 UI を実装する（ソース未登録時のガイダンスメッセージ・設定画面へのリンク）
- [ ] T041 [P] `FeedView.swift` にソース部分失敗通知 UI を実装する（失敗ソース名を `errorMessage` として表示）
- [ ] T042 [P] WCAG 2.1 AA 準拠のアクセシビリティ対応を実施する（全ビュー対象）:
  - `NewsApp/Views/Feed/CardView.swift`: スワイプカードに `accessibilityLabel`・`accessibilityHint` を追加する（VoiceOver でタイトル＋概要が読まれる）
  - `NewsApp/Views/Feed/FeedView.swift`: リロードボタン・Undo ボタンに `accessibilityLabel` を追加する
  - `NewsApp/Views/Settings/SourceListView.swift`: 追加・削除操作に `accessibilityLabel` を追加する
- [ ] T046 [P] WCAG 2.1 AA 準拠チェックを実施する（Simulator の Accessibility Inspector で検証）:
  - コントラスト比 ≥4.5:1（テキスト）をテキストカラーで確認する
  - タップ領域 ≥44×44pt をすべてのボタン・スワイプ要素で確認する
  - Dynamic Type（最大文字サイズ）でレイアウト崩れがないことを確認する
- [ ] T043 `quickstart.md` の全検証手順を実機または Simulator で実行して通過を確認する
- [ ] T044 [P] 全ユニット・統合テストを実行する（`Cmd+U`）、失敗テストを修正する
- [ ] T047 SC-001/SC-002 およびデータクエリのパフォーマンスを計測して記録する:
  - `NewsAppTests/Performance/PerformanceTests.swift` を作成する
  - SC-001: `XCTApplicationLaunchMetric()` でアプリ起動〜初回カード表示を計測し ≤3秒を確認する
  - SC-002: DragGesture 確定から `UIActivityViewController` 表示までを `XCTClockMetric` で計測し ≤1秒を確認する
  - SwiftData `@Query`（未スワイプ記事 350件時）の応答時間を `XCTClockMetric` で計測し ≤200ms を確認する（憲法 II 準拠）
- [ ] T045 `specs/001-personalized-news-feed/checklists/requirements.md` の全項目を確認し FR-001〜FR-016 がすべてタスクでカバーされていることを検証する

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: 依存なし — すぐに開始可能
- **Foundational (Phase 2)**: Phase 1 完了後 — **全ユーザーストーリーをブロック**
- **User Story 1 (Phase 3)**: Phase 2 完了後 — T021a で `PersonalizationService` スタブを作成してから T021・T022 を実装する。本実装は US3（T032-T033）で行う
- **User Story 2 (Phase 4)**: Phase 2 完了後 — US1 と並列実行可能
- **User Story 3 (Phase 5)**: Phase 2 完了後、かつ US1 の `recordSignal` 統合前に完了推奨
- **Polish (Phase 6)**: 実装したい全ストーリーの完了後

### User Story Dependencies

- **US1 (P1)**: Phase 2 完了後すぐ開始可能（PersonalizationService はスタブで代替）
- **US2 (P2)**: Phase 2 完了後すぐ開始可能（US1 と完全独立）
- **US3 (P3)**: Phase 2 完了後開始可能、US1 の `recordSignal` 統合（T038）の前に T032-T033 を完了させること

### Within Each User Story

1. テストを書いて**失敗を確認**する（Red）
2. Model / Protocol → Service → View の順で実装する
3. テストが通ることを確認する（Green）
4. Checkpoint を実機/Simulator で検証してから次のフェーズへ

### Parallel Opportunities

- T003・T004 は T001 完了後に並列実行可
- T006・T007・T010・T011・T012 は T005 と並列実行可
- T013・T014 は並列実行可（先にテストを書く）
- T021a は T013・T014 の後、T021・T022 の前に完了させること
- T018・T020 は他の US1 タスクと並列実行可
- T026・T030・T031 は並列実行可（テストを先に書く）

---

## Parallel Example: User Story 1

```bash
# テストを先に書く（並列）:
Task: "RSSParserService 単体テスト - NewsAppTests/Unit/RSSParserServiceTests.swift"
Task: "NewsCollectorService 統合テスト - NewsAppTests/Integration/NewsCollectorIntegrationTests.swift"

# テスト失敗を確認してから実装:
Task: "RSSParserService 実装 - NewsApp/Services/RSSParserService.swift"
→ 上記完了後 →
Task: "NewsCollectorService 実装 - NewsApp/Services/NewsCollectorService.swift"

# UI は並列実装可能:
Task: "CardView 実装 - NewsApp/Views/Feed/CardView.swift"
Task: "ShareSheet 実装 - NewsApp/Views/Feed/ShareSheet.swift"
```

---

## Implementation Strategy

### MVP First (User Story 1 のみ)

1. Phase 1: Setup 完了
2. Phase 2: Foundational 完了（CRITICAL — 全ストーリーをブロック）
3. Phase 3: User Story 1 完了
4. **STOP and VALIDATE**: quickstart.md P1 検証手順をすべてパス
5. デプロイ（実機インストール）して実際に使い始める

### Incremental Delivery

1. Setup + Foundational → 骨格完成
2. US1 → テスト・検証 → 実機で使い始める（MVP！）
3. US2 → テスト・検証 → ソース管理が便利になる
4. US3 → テスト・検証 → パーソナライズが効き始める
5. 各ストーリーは前のストーリーを壊さない

---

## Notes

- [P] = 異なるファイル、依存なし → 並列実行可能
- [US*] ラベルはユーザーストーリーへのトレーサビリティ
- テストは**実装前**に書き、**失敗を確認**してから実装する（憲法 III）
- 各 Checkpoint でストーリーを独立検証してから次へ進む
- `PersonalizationService` を US1 で利用する箇所（T021・T022）はスタブ実装可、US3（T032・T033）で本実装する
