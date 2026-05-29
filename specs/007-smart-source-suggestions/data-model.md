# Data Model: 利用統計に基づくおすすめソースの自動調整

**Branch**: `007-smart-source-suggestions` | **Date**: 2026-05-29

## 変更エンティティ: SuggestedSource（既存 struct の拡張）

### 追加フィールド

| フィールド | 型 | 説明 |
|-----------|-----|------|
| `keywords` | `[String]` | そのソースの主な話題を表す代表キーワード群（小文字）。利用シグナルとの照合に使用 |

### 変更後の定義

```
SuggestedSource (struct, 非永続)
├── name: String
├── feedURL: String
└── keywords: [String]   ← NEW
```

### キーワード割り当て（静的定義）

| ソース | 代表キーワード（小文字、日英混在） |
|--------|----------------------------------|
| NHK ニュース | ニュース, 速報, 政治, 社会, 国内 |
| 朝日新聞 デジタル | ニュース, 政治, 社会, 経済, 国際 |
| 毎日新聞 | ニュース, 政治, 社会, 事件 |
| Reuters Japan | 経済, 国際, ビジネス, 金融, マーケット |
| Gigazine | テクノロジー, ガジェット, 科学, レビュー |
| TechCrunch Japan | tech, テクノロジー, スタートアップ, アプリ, ai |
| Hacker News | tech, プログラミング, スタートアップ, ソフトウェア |

> 注: `InterestSignal.keyword` は `NLTagger` で抽出した名詞を `lowercased()` で格納するため、英単語キーワードも小文字で定義する。具体的な語は実装時に調整可。

## 既存エンティティ（変更なし、入力として利用）

- **InterestSignal**: `keyword`（小文字名詞）, `signalType`（shared/notInterested）, `weight`（+2 / -3）, `sourceName`, `recordedAt`
- **NewsSource**: `feedURL`（追加済み判定に使用）

## 新規ロジック: SuggestedSources.ranked

```
SuggestedSources.ranked(excluding addedURLs: Set<String>, signals: [InterestSignal]) -> [SuggestedSource]
```

### アルゴリズム

1. `all` から `addedURLs` に含まれる feedURL を除外（既存 `filtered` と同じ重複防止）
2. シグナルをキーワード別に集計し重みマップ `[String: Double]` を作る（共有 +2 / 興味なし -3 の合算）
3. 各 SuggestedSource のスコア = `keywords` のうち重みマップに存在するものの重み合計
4. スコア降順でソート。**同点時は `all` の定義順（元インデックス昇順）を維持**

### 出力

並び替え済みの `[SuggestedSource]`（除外後の全件）。

### バリデーション/不変条件

- 追加済みソースは出力に含まれない（FR-005）
- シグナルが空（新規ユーザー）の場合、全件スコア 0 → 定義順で返す（FR-004, SC-002）
- 件数の絞り込みは行わない（FR-007、除外後の全件を返す）
