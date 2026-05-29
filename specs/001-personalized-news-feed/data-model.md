# Data Model: パーソナライズドニュースフィード

**Branch**: `001-personalized-news-feed` | **Date**: 2026-05-29

---

## 永続化戦略

| ストア | 用途 |
|--------|------|
| SwiftData | Article・NewsSource・InterestSignal の永続化 |
| UserDefaults | Obsidian Vault の security-scoped bookmark データ、設定値 |
| In-memory | ObsidianContext（起動時スキャン結果、セッション限り） |

---

## エンティティ定義

### Article（記事）

SwiftData `@Model`

| フィールド | 型 | 説明 |
|-----------|-----|------|
| `id` | `UUID` | 主キー（自動生成） |
| `url` | `String` | 元記事 URL（一意キー・重複除去に使用） |
| `title` | `String` | 記事タイトル |
| `summary` | `String` | 概要テキスト（数行） |
| `sourceName` | `String` | ソース名（表示用） |
| `sourceURL` | `String` | ソース RSS URL |
| `fetchedAt` | `Date` | 取得日時 |
| `swipeAction` | `SwipeAction?` | `nil`=未スワイプ、`.shared`=共有済み、`.notInterested`=興味なし |
| `score` | `Double` | パーソナライズスコア（ソート用、デフォルト0.0） |

**制約**:
- `url` はインデックス付き（重複チェックに `@Attribute(.unique)` を使用）
- `swipeAction != nil` かつ `fetchedAt` が7日以上前の Article は定期削除対象
- 取得済みだが未スワイプの Article は次回フェッチ時もスタックに残る

**状態遷移**:
```
[未スワイプ] --右スワイプ--> [shared]
             --左スワイプ--> [notInterested]
[shared / notInterested] --7日経過--> [削除]
```

---

### NewsSource（ニュースソース）

SwiftData `@Model`

| フィールド | 型 | 説明 |
|-----------|-----|------|
| `id` | `UUID` | 主キー |
| `name` | `String` | 表示名（ユーザー入力または RSS タイトルから自動取得） |
| `feedURL` | `String` | RSS / Atom フィードの URL |
| `isEnabled` | `Bool` | true=取得対象、false=スキップ（削除の代わりに無効化も可） |
| `addedAt` | `Date` | 登録日時 |

**制約**:
- `feedURL` は一意（重複登録不可）
- 削除時: そのソースから取得した未スワイプ Article は次回フェッチ対象外になる（即時削除はしない）

---

### InterestSignal（興味シグナル）

SwiftData `@Model`

| フィールド | 型 | 説明 |
|-----------|-----|------|
| `id` | `UUID` | 主キー |
| `keyword` | `String` | 抽出キーワード（NLTokenizer による名詞） |
| `signalType` | `SignalType` | `.shared`（+2）または `.notInterested`（-3） |
| `sourceName` | `String` | シグナル元のソース名 |
| `recordedAt` | `Date` | 記録日時 |

**制約**:
- 1回のスワイプで複数の InterestSignal が生成される（記事タイトル＋概要からのキーワード数分）
- `recordedAt` が7日以上前のシグナルも記事と同様に削除対象

---

### ObsidianContext（Obsidianコンテキスト）

**In-memory struct（永続化なし）** — アプリ起動時に生成・破棄

| フィールド | 型 | 説明 |
|-----------|-----|------|
| `keywords` | `[String: Double]` | キーワード → 重み（出現頻度 × +1.0） |
| `lastScannedAt` | `Date` | スキャン完了日時 |
| `vaultBookmarkData` | `Data?` | UserDefaults から読み込んだ bookmark（セッション管理用） |

**Vault 設定**:
- UserDefaults key `obsidian_vault_bookmark`: `Data?`（security-scoped URL bookmark）
- UserDefaults key `obsidian_vault_last_scanned`: `Date?`

---

## 列挙型

```swift
enum SwipeAction: String, Codable {
    case shared          // 右スワイプ（Readwise Readerへ共有）
    case notInterested   // 左スワイプ（興味なし）
}

enum SignalType: String, Codable {
    case shared          // 共有済み記事由来 (weight: +2.0)
    case notInterested   // 興味なし記事由来 (weight: -3.0)
}
```

---

## インデックスと検索パターン

| クエリ | フィールド | 用途 |
|--------|-----------|------|
| 未スワイプ記事をスコア降順で取得 | `swipeAction == nil`, `score DESC` | メインスタック表示 |
| URL重複チェック | `url` | 取得時の重複除去 |
| 7日以上前のスワイプ済み記事を取得 | `swipeAction != nil`, `fetchedAt < now-7days` | 定期クリーンアップ |
| キーワード別シグナル集計 | `keyword`, `signalType` | スコアリング辞書の構築 |

---

## データ量見積もり

| エンティティ | 想定件数 | 備考 |
|-------------|---------|------|
| Article | ≤ 350件 | 最大50件/回 × 7日分 |
| NewsSource | ≤ 20件 | ユーザーが手動登録 |
| InterestSignal | ≤ 10,000件 | 記事1件あたり平均20キーワード × 350件 × 7日 |
| ObsidianContext.keywords | ≤ 5,000エントリ | Vault の規模依存 |
