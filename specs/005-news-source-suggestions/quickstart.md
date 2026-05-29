# Quickstart: おすすめニュースソースサジェスト

**Branch**: `005-news-source-suggestions` | **Date**: 2026-05-29

## ビルドと実行

```bash
# プロジェクト生成
xcodegen generate

# テスト実行（実装前: RED → 実装後: GREEN を確認）
xcodebuild test \
  -scheme NewsApp \
  -destination 'platform=iOS Simulator,name=iPhone Air,OS=26.4.1' \
  -only-testing:NewsAppTests/Unit/SuggestedSourcesTests \
  2>&1 | grep -E "Test (passed|failed|Suite)"

# 全テスト実行
xcodebuild test \
  -scheme NewsApp \
  -destination 'platform=iOS Simulator,name=iPhone Air,OS=26.4.1' \
  2>&1 | grep -E "Test (passed|failed|Suite|started)"
```

## 検証チェックリスト

### 機能確認

1. **ソース追加シートを開く**
   - [ ] 設定 → ニュースソース → `+` をタップ
   - [ ] シート上部に「おすすめ」セクションが表示される（≥5件）

2. **ワンタップ追加**
   - [ ] おすすめリストの任意のソースをタップ
   - [ ] ニュースソース一覧に即座に追加される
   - [ ] タップしたソースがおすすめリストから消える
   - [ ] シートは開いたまま

3. **重複防止**
   - [ ] 同じソースを再度タップしようとしても、リストに表示されない

4. **全件追加後**
   - [ ] おすすめソースをすべて追加すると「おすすめ」セクションが非表示になる
   - [ ] URL 手動入力フォームは引き続き表示される

5. **手動入力との共存**
   - [ ] おすすめリスト表示中も URL フィールドへの手入力が可能
   - [ ] 手動入力したソースが正常に追加される

### テスト確認

```bash
# 期待結果: SuggestedSourcesTests の全テストが PASS
xcodebuild test \
  -scheme NewsApp \
  -destination 'platform=iOS Simulator,name=iPhone Air,OS=26.4.1' \
  2>&1 | grep -E "(passed|failed)"
```

期待: `Test Suite 'All tests' passed`（28件 → 33件以上）
