# Service Interface Contracts: パーソナライズドニュースフィード

**Branch**: `001-personalized-news-feed` | **Date**: 2026-05-29

これらはアプリ内サービス間の境界を定義します。実装言語は Swift。

---

## NewsCollectorService

ニュースソースから記事を収集し、重複除去・永続化を行う。

```swift
protocol NewsCollectorServiceProtocol {
    /// 登録済みの全有効ソースから記事を取得する
    /// - Returns: 新規取得した記事数（重複除去後）
    /// - Throws: 全ソースが失敗した場合のみエラー。部分失敗はログのみ
    func fetchAll() async throws -> Int

    /// 特定ソースから記事を取得する
    /// - Parameter source: 取得対象ソース
    /// - Returns: 取得した記事（重複除去前）
    func fetch(from source: NewsSource) async throws -> [Article]
}
```

**契約**:
- 部分失敗（一部ソースがエラー）の場合、成功したソースの記事を返して処理継続する
- 全ソースが失敗した場合のみ `throw` する
- 取得後に URL 重複除去（既存 Article との照合）を実施する
- 取得件数が50件を超えた場合、スコアリング後に上位50件のみをスタック先頭に追加する
- フェッチ完了後、新規記事の InterestSignal 生成はPersonalizationServiceに委ねる

---

## RSSParserService

RSS / Atom フィードを Article の配列に変換する。

```swift
protocol RSSParserServiceProtocol {
    /// フィード URL をフェッチしてパースする
    /// - Parameter feedURL: RSS / Atom フィードの URL 文字列
    /// - Returns: パース済み記事の配列（タイトル・概要・URL・取得日時を含む）
    /// - Throws: URLSession エラー、パースエラー
    func parse(feedURL: String) async throws -> [RawArticle]
}

struct RawArticle {
    let title: String
    let summary: String  // RSS の <description> または Atom の <summary>
    let url: String
    let publishedAt: Date?
    let sourceName: String
}
```

**契約**:
- summary が空の場合は `title` を summary に使用する
- `url` が空または無効な場合はその記事をスキップする
- RSS 2.0 と Atom 1.0 の両方に対応する

---

## PersonalizationService

InterestSignal と ObsidianContext を基にスコア辞書を構築し、記事にスコアを付与する。

```swift
protocol PersonalizationServiceProtocol {
    /// 記事群にパーソナライズスコアを付与してスコア降順でソートする
    /// - Parameters:
    ///   - articles: スコアリング対象の記事
    ///   - signals: InterestSignal 一覧
    ///   - obsidianContext: Obsidian キーワードコンテキスト（nil の場合は使用しない）
    /// - Returns: score フィールドが更新された記事をスコア降順で返す
    func score(
        articles: [Article],
        signals: [InterestSignal],
        obsidianContext: ObsidianContext?
    ) -> [Article]

    /// スワイプ操作から InterestSignal を生成して保存する
    /// - Parameters:
    ///   - article: スワイプされた記事
    ///   - action: スワイプ種別
    func recordSignal(for article: Article, action: SwipeAction) async
}
```

**契約**:
- シグナル重み: `.shared` キーワード → +2.0、`.notInterested` キーワード → -3.0、Obsidian キーワード → +1.0
- キーワード抽出は `NLTokenizer` を使用し、タイトル＋概要から名詞（2文字以上）を抽出する
- スコアが同値の場合は `fetchedAt` 降順（新着優先）
- Obsidian コンテキストが nil（未設定/読み取り失敗）の場合は in-app シグナルのみでスコアリングする

---

## ObsidianReaderService

ローカル Obsidian Vault フォルダから Markdown を読み取りキーワードを抽出する。

```swift
protocol ObsidianReaderServiceProtocol {
    /// Vault フォルダから全 .md ファイルを読み取り、キーワード頻度マップを返す
    /// - Parameter bookmarkData: UserDefaults に保存された security-scoped URL bookmark
    /// - Returns: キーワード → 出現頻度の辞書
    /// - Throws: bookmark アクセス失敗、ファイル読み取りエラー
    func extractKeywords(from bookmarkData: Data) async throws -> [String: Int]

    /// UIDocumentPickerViewController で選択されたフォルダ URL を bookmark として保存する
    /// - Parameter folderURL: ユーザーが選択したフォルダの security-scoped URL
    func saveVaultBookmark(for folderURL: URL) throws
}
```

**契約**:
- `.md` ファイルのみ対象（`.pdf` 等はスキップ）
- frontmatter（`---` で囲まれたブロック）はキーワード抽出から除外する
- 読み取り完了後は `stopAccessingSecurityScopedResource()` を必ず呼ぶ
- エラー発生時は呼び出し元に throw し、アプリは Obsidian シグナルなしで動作継続する

---

## FeedViewModel（UI ↔ Service の契約）

| 入力イベント | 処理 |
|-------------|------|
| ビュー表示 | 未スワイプ記事をスコア降順で `@Query` ロード |
| 右スワイプ | 共有シート起動 → `PersonalizationService.recordSignal(.shared)` |
| 左スワイプ | `PersonalizationService.recordSignal(.notInterested)` → カード除去 |
| Undo | 直前スワイプを取り消し（Article.swipeAction を nil に戻す） |
| 手動リロード | `NewsCollectorService.fetchAll()` → スタック更新 |

| 出力状態 | 型 |
|---------|-----|
| `articles` | `[Article]`（未スワイプ、スコア降順） |
| `isLoading` | `Bool` |
| `errorMessage` | `String?` |
| `lastSwipedArticle` | `Article?`（Undo 用） |
