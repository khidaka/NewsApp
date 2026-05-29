# Quickstart Validation: 利用統計に基づくおすすめソースの自動調整

**Branch**: `007-smart-source-suggestions` | **Date**: 2026-05-29

## ビルド & テスト

```bash
xcodegen generate
xcodebuild -scheme NewsApp \
  -destination 'platform=iOS Simulator,name=iPhone Air,OS=26.4.1' build
xcodebuild test -scheme NewsApp \
  -destination 'platform=iOS Simulator,name=iPhone Air,OS=26.4.1'
```

## 手動検証チェックリスト

### SC-002: 新規ユーザーは既定順

1. クリーンな状態でアプリを起動（または全シグナル無しの状態）
2. 設定 → ニュースソース → ＋ でソース追加シートを開く
3. おすすめが現行の静的順（NHK → 朝日 → 毎日 → Reuters → Gigazine → TechCrunch → Hacker News）で並ぶことを確認 ✓

### SC-001: 利用傾向が上位に反映される

1. フィードでテック系の記事（TechCrunch / Gigazine / Hacker News 由来）を繰り返し右スワイプ（共有）する
2. ソース追加シートを開く
3. テック系のおすすめ（TechCrunch / Gigazine / Hacker News）が上位（上位3位以内）に並ぶことを確認 ✓
4. 逆に、ある傾向の記事を「興味なし」（左スワイプ）にすると、対応ソースが下位に下がることを確認 ✓

### SC-003: 遅延なし

1. ソース追加シートを開いた際、おすすめリストが即座に表示されることを確認（待ち時間を感じない）✓

### SC-004: 追加済みソースの除外（feature 005 維持）

1. おすすめからいくつかをワンタップ追加
2. シートを開き直し、追加済みソースがおすすめに表示されないことを確認 ✓

## 回帰テスト確認項目

- おすすめのワンタップ追加が引き続き機能する（feature 005）
- 手動 URL 入力での追加が引き続き機能する
- ソースの削除が引き続き機能する
- スキップ永続化（feature 006）に影響がない
