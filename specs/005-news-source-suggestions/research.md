# Research: おすすめニュースソースサジェスト

**Branch**: `005-news-source-suggestions` | **Date**: 2026-05-29

## Decision 1: おすすめリストのデータ格納方式

**Decision**: Swift ファイル内の静的配列（`static let all: [SuggestedSource]`）

**Rationale**: 個人アプリで外部配信・動的更新が不要。JSON/plistより型安全でコンパイル時検証が効く。ビルド成果物を増やさない。

**Alternatives considered**:
- JSON バンドルリソース: 不要な動的パース処理が加わり、V1 のシンプルさを損なう
- plist: Swift array より冗長で得られるメリットなし
- ネットワーク取得: オフライン利用不可・複雑性増大・V1スコープ外

---

## Decision 2: SuggestedSource の型設計

**Decision**: `struct SuggestedSource` — 値型の単純構造体（SwiftData モデルではない）

**Rationale**: バンドル済み静的データであり永続化不要。`Hashable` 準拠で Set 操作が容易になる。

**Alternatives considered**:
- SwiftData `@Model`: 不要な永続化オーバーヘッド。静的データをDBに入れる合理的理由なし。
- タプル: 型名がなく可読性・テスタビリティが落ちる

---

## Decision 3: 追加済みソースのフィルタリング方式

**Decision**: `SourceListView` の computed property `filteredSuggestions` で `feedURL` 完全一致による差分計算

```swift
var filteredSuggestions: [SuggestedSource] {
    let addedURLs = Set(sources.map(\.feedURL))
    return SuggestedSources.all.filter { !addedURLs.contains($0.feedURL) }
}
```

**Rationale**: `@Query` が SwiftData の変更を自動検知して `sources` を更新するため、タップ後に `filteredSuggestions` が自動的に再計算される。シートを閉じずに追加済みソースが即座に消える挙動が SwiftUI のリアクティブ性で自然に実現できる。

**Alternatives considered**:
- 追加済みフラグを持つ別モデル: 余分な状態管理が発生し Simplicity 原則に反する
- 全件表示してグレーアウト: スペックで「表示しない」と決定済み (FR-005)

---

## Decision 4: UI レイアウト方式

**Decision**: 既存の `addSourceSheet` の `Form` の先頭に `Section("おすすめ")` を追加

```swift
Form {
    if !filteredSuggestions.isEmpty {
        Section("おすすめ") {
            ForEach(filteredSuggestions, id: \.feedURL) { suggestion in
                Button(suggestion.name) { addSuggestion(suggestion) }
            }
        }
    }
    Section("フィード URL") { ... }  // 既存
    Section("表示名（省略可）") { ... }  // 既存
}
```

**Rationale**: 既存の Form/Section 構造を最小限の変更で拡張できる。SwiftUI の `if !filteredSuggestions.isEmpty` で全追加済み時のセクション自動非表示も実現。

---

## Decision 5: おすすめソースのカタログ内容

**Decision**: 以下の日本語ニュース RSS を初期ラインナップとして採用（≥5件、FR-008 準拠）

| 名前 | フィード URL |
|------|-------------|
| NHK ニュース | https://www.nhk.or.jp/rss/news/cat0.xml |
| 朝日新聞 デジタル | https://www.asahi.com/rss/asahi/newsheadlines.rdf |
| 毎日新聞 | https://mainichi.jp/rss/etc/mainichi-flash.rss |
| Reuters Japan | https://feeds.reuters.com/reuters/JPTopNews |
| Gigazine | https://gigazine.net/news/rss_2.0/ |
| TechCrunch Japan | https://jp.techcrunch.com/feed/ |
| Hacker News (英語) | https://news.ycombinator.com/rss |

**Rationale**: 日本語ニュース中心（NHK・朝日・毎日・Reuters JP）＋テック系（Gigazine・TCJ・HN）でユーザーのニーズをカバー。実装者はURLの有効性を事前確認すること。

---

## Decision 6: テスト戦略

**Decision**: `NewsAppTests/Unit/SuggestedSourcesTests.swift` で以下をテスト

1. `SuggestedSources.all` が 5 件以上含むこと (FR-008)
2. `filteredSuggestions` のフィルタリングロジック（既登録URLが除外されること）
3. 全件追加済み時に結果が空になること
4. `SettingsViewModel.addSource` を経由した追加が既存テストでカバー済み

**Rationale**: 憲法 III (Test-First) に従い実装前にテストを書く。SwiftUI View のロジックは ViewModel/Service に切り出さなくても、テスト用のヘルパー関数として抽出してテスト可能にする。
