# Data Model: おすすめニュースソースサジェスト

**Branch**: `005-news-source-suggestions` | **Date**: 2026-05-29

## SuggestedSource（新規）

バンドル済みの静的おすすめソース定義。SwiftData モデルではなく値型構造体。

```swift
struct SuggestedSource: Hashable {
    let name: String      // 表示名（例: "NHK ニュース"）
    let feedURL: String   // RSS フィード URL（一意キー）
}
```

**制約**:
- `feedURL` はカタログ内で一意でなければならない
- `name` は空文字列不可
- `feedURL` は `http://` または `https://` で始まる有効な URL

**関連**: `NewsSource.feedURL` と完全一致比較でフィルタリング（正規化なし）

---

## SuggestedSources カタログ（新規）

```swift
enum SuggestedSources {
    static let all: [SuggestedSource] = [
        SuggestedSource(name: "NHK ニュース",        feedURL: "https://www.nhk.or.jp/rss/news/cat0.xml"),
        SuggestedSource(name: "朝日新聞 デジタル",   feedURL: "https://www.asahi.com/rss/asahi/newsheadlines.rdf"),
        SuggestedSource(name: "毎日新聞",             feedURL: "https://mainichi.jp/rss/etc/mainichi-flash.rss"),
        SuggestedSource(name: "Reuters Japan",        feedURL: "https://feeds.reuters.com/reuters/JPTopNews"),
        SuggestedSource(name: "Gigazine",             feedURL: "https://gigazine.net/news/rss_2.0/"),
        SuggestedSource(name: "TechCrunch Japan",     feedURL: "https://jp.techcrunch.com/feed/"),
        SuggestedSource(name: "Hacker News",          feedURL: "https://news.ycombinator.com/rss"),
    ]
}
```

---

## NewsSource（既存・変更なし）

```swift
@Model final class NewsSource {
    @Attribute(.unique) var feedURL: String
    var id: UUID
    var name: String
    var isEnabled: Bool
    var addedAt: Date
}
```

---

## フィルタリングロジック

`SourceListView` の computed property として実装:

```swift
var filteredSuggestions: [SuggestedSource] {
    let addedURLs = Set(sources.map(\.feedURL))
    return SuggestedSources.all.filter { !addedURLs.contains($0.feedURL) }
}
```

`@Query` の `sources` が SwiftData の更新を検知 → `filteredSuggestions` が自動再計算 → UI が即座に更新される。

---

## 状態遷移

```
おすすめソース状態:
  未追加 → (タップ) → 追加済み（リストから消える）

シート状態:
  開いている → (タップ) → 開いたまま（複数追加可能）
  開いている → (キャンセル/完了ボタン) → 閉じる
  開いている → (全ソース追加) → おすすめセクションのみ非表示、フォームは継続表示
```
