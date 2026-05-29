# Research: 利用統計に基づくおすすめソースの自動調整

**Branch**: `007-smart-source-suggestions` | **Date**: 2026-05-29

## Decision 1: スコア算出ロジック

**Decision**: `SuggestedSource` に代表キーワード群 `keywords: [String]` を追加し、既存 `PersonalizationService` のキーワード重みマップ（`InterestSignal` 集計）と突き合わせてスコアを算出する

**Rationale**:
- 既存 `PersonalizationService.buildWeightMap(signals:)` がすでに `[String: Double]`（キーワード→重み合計）を生成している。これを再利用すれば新規ロジックが最小
- `InterestSignal.keyword` は `NLTagger` で抽出した名詞を `lowercased()` で格納。`SuggestedSource.keywords` も小文字で定義すれば一致判定が単純
- スコア = `source.keywords.reduce(0) { $0 + (weightMap[$1] ?? 0) }` の一行で表現可能（記事スコアリングと同じパターン）

**Alternatives Considered**:
- ジャンル分類で照合（Clarifications Option B）: シグナルにジャンル情報がなく、別途マッピングが必要で複雑。不採用（Q1 で A を選択）
- 追加済みソースのエンゲージメント傾向で照合: `InterestSignal.sourceName` はあるが、未追加のおすすめソースとは名前が一致しないため橋渡しにならない。不採用

## Decision 2: スコア計算の責務配置

**Decision**: スコアリングとソートを担う純粋関数を `SuggestedSources`（enum）に追加する。`InterestSignal` の取得は View 側の `@Query` で行い、関数に渡す

**Rationale**:
- `SuggestedSources` はすでに `filtered(excluding:)` という静的ユーティリティを持つ。同じ場所に `ranked(excluding:signals:)` を追加するのが自然で凝集度が高い
- 純粋関数（入力: 除外URL集合 + シグナル配列 → 出力: 並び替え済み配列）にすることで単体テストが容易（Constitution III）
- SwiftData アクセスは View の `@Query` に委ね、ロジックは I/O を持たない

**Alternatives Considered**:
- `SettingsViewModel` にロジックを置く: ViewModel は SwiftData 書き込み（addSource/deleteSource）が責務。並び替えは静的ユーティリティの方が単純で再利用しやすい。不採用

## Decision 3: 同点時のソート安定性

**Decision**: スコア降順でソートし、同点時は `SuggestedSources.all` の定義順（インデックス）を保つ

**Rationale**:
- Clarifications Q2 で確定。新規ユーザー（全件0点）は定義順になり FR-004 と一致
- Swift の `sorted(by:)` は安定ソートではないため、明示的にインデックスをタイブレークに使う（`score 降順 → 元インデックス昇順`）
- これによりテストの再現性が保証される（SC-002）

## Decision 4: 再計算タイミング

**Decision**: `filteredSuggestions` 相当の computed property を `ranked(...)` 呼び出しに置き換え、シート表示時（View 評価時）に毎回計算する

**Rationale**:
- FR-008 で「シートを開くたびに再計算」が確定。SwiftUI の computed property は body 評価のたびに走るため、追加のキャッシュ機構は不要
- スコア計算は 7 ソース × 数件キーワード × 重みマップ参照のみで軽量（SC-003 の遅延なしを満たす）

## Decision 5: キーワード設計

**Decision**: 各おすすめソースに、そのソースの主な話題を表す小文字キーワードを 3〜5 個手動で付与する

**Rationale**:
- 7 ソースは固定なので、各ソースの代表キーワードもコード内に静的定義できる
- 例: TechCrunch Japan → ["tech", "テクノロジー", "スタートアップ", "アプリ"]、NHK → ["ニュース", "速報", "政治", "社会"]
- `InterestSignal.keyword` は名詞抽出結果なので、日本語名詞・英単語の両方を含めて一致率を高める

**Note**: キーワードの具体的な割り当ては data-model.md に記載。一致率は実利用で調整余地あり（YAGNI: 初期は手動定義で十分）
