# Research: パーソナライズドニュースフィード

**Branch**: `001-personalized-news-feed` | **Date**: 2026-05-29

---

## 1. RSS/Atom フィードパーシング

**Decision**: **FeedKit** (Swift Package Manager) を採用する

**Rationale**:
- RSS 2.0 / Atom / JSON Feed の3形式をすべてカバー
- 日本語ニュースサイトは RSS 2.0 と Atom が混在するため、マルチフォーマット対応が必須
- 純 Swift 実装、型安全、メンテ継続中
- ネイティブ `XMLParser` による自前実装は同等機能を得るのに数倍の工数

**Alternatives considered**:
- `Foundation.XMLParser` 自前実装 → 工数大、RSS/Atom の差異吸収が煩雑
- `SwiftSoup` (HTML scraping) → スクレイピングは憲法「主手段としない」に抵触

---

## 2. データ永続化

**Decision**: **SwiftData** (iOS 17+) を採用する

**Rationale**:
- `@Model` マクロで型安全・最小ボイラープレート
- `@Query` による SwiftUI との直接バインディング（ViewModel への変換不要なケースも）
- iOS 17 ターゲットで安定版として利用可能
- 個人用アプリで複雑なマイグレーションシナリオは発生しにくい

**Alternatives considered**:
- Core Data → より成熟しているが記述量が多い。SwiftData は Core Data の上に構築されており信頼性は同等
- SQLite (GRDB 等) → SPM 依存が増える、SwiftData と比べてメリットなし

**Settings/Bookmarks**: `UserDefaults` に Obsidian Vault の security-scoped URL bookmark データを保存する

---

## 3. バックグラウンドフェッチ

**Decision**: **BGTaskScheduler** (`BGAppRefreshTask`) を採用する

**Rationale**:
- iOS 公式のバックグラウンド処理 API
- iOS がバッテリー・ネットワーク状況に基づいて最適タイミングで実行（省電力）
- `Info.plist` に `BGTaskSchedulerPermittedIdentifiers` を登録し、タスク完了後に次回スケジュールを再登録する標準パターン

**Constraints**:
- iOS はバックグラウンドタスクの実行を保証しない（省電力優先）
- タスクあたりの実行時間は約30秒が上限
- 手動リロード（フォアグラウンド）は制限なし

---

## 4. Obsidian Vault ファイルアクセス

**Decision**: `UIDocumentPickerViewController` + **security-scoped URL bookmark** を採用する

**Rationale**:
- ユーザーが一度フォルダを選択すれば、bookmark を UserDefaults に保存して以降のアクセスが可能
- `startAccessingSecurityScopedResource()` / `stopAccessingSecurityScopedResource()` のライフサイクルを遵守
- iCloud Drive 上の Obsidian Vault フォルダへのアクセスはこのパターンが iOS 標準

**Markdown parsing**: `.md` ファイルを `String(contentsOf:)` で読み込み、行単位・単語単位で処理。frontmatter (`---` ブロック) はスキップ。

---

## 5. 日本語キーワード抽出

**Decision**: **Apple NaturalLanguage framework** (`NLTokenizer`, `NLTagger`) を採用する

**Rationale**:
- iOS 標準フレームワーク、外部依存なし
- `NLTokenizer` の `.word` 単位トークナイズが日本語に対応（Unicode 分割）
- `NLTagger` の `.lexicalClass` タグで名詞・固有名詞を抽出可能
- 個人用アプリに MeCab を組み込む工数・複雑性に見合わない

**Stopword filtering**: 助詞・助動詞・記号などの短いトークン（2文字未満）はフィルタリングする

---

## 6. パーソナライズスコアリングアルゴリズム

**Decision**: **加重キーワードスコアリング** を採用する

**Algorithm**:
```
1. キーワード辞書を構築（起動時）:
   - 共有（右スワイプ）記事のキーワード: weight = +2.0
   - 興味なし（左スワイプ）記事のキーワード: weight = -3.0
   - Obsidian ノートの頻出キーワード: weight = +1.0（出現頻度に比例）

2. 記事スコア計算:
   score(article) = Σ(keyword_weight × IDF(keyword))
   - IDF(keyword) = log(total_articles / (1 + articles_containing_keyword))
   - スコアは正規化しない（相対比較に使用）

3. 50件をスコア降順でソートしてスタックに積む
```

**Alternatives considered**:
- TF-IDF 完全実装 → TF は短い summary では効果薄。IDF のみで十分
- ニューラルネット埋め込み → 個人用アプリには過剰、実行時コスト高

---

## 7. スワイプカード UI

**Decision**: SwiftUI **DragGesture** + **offset animation** を採用する

**Rationale**:
- 外部ライブラリ不要
- `.gesture(DragGesture())` で水平オフセットを追跡
- オフセット ≥ 画面幅 × 0.4 で左右どちらかのアクション確定
- `withAnimation(.spring())` でカードをフライアウトさせる

---

## 8. iOS 共有シート（Share Sheet）

**Decision**: `UIActivityViewController` を `UIViewControllerRepresentable` でラップする

**Rationale**:
- SwiftUI ネイティブの `.shareLink` は URL のみで概要テキストを渡せない
- `UIActivityViewController(activityItems: [url, title])` で URL + タイトル両方を渡せる
- Readwise Reader はシステム共有シート経由での URL 受け取りに対応済み

---

## 9. ターゲット iOS バージョン

**Decision**: **iOS 17.0+**

**Rationale**:
- SwiftData は iOS 17 で一般提供開始
- BGTaskScheduler は iOS 13+ だが、開発者（ユーザー本人）のデバイスは最新 iOS を維持可能
- iOS 17 の SwiftUI 改善（`scrollPosition`, `Observable` マクロ等）を活用できる
