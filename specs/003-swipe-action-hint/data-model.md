# Data Model: スワイプアクションヒント

**Branch**: `003-swipe-action-hint` | **Date**: 2026-05-29

---

## SwiftData スキーマ変更

**なし** — 表示専用の UI 機能のため、永続化データへの変更は不要。

---

## CardView の状態追加（インメモリ）

### 追加フィールド

| フィールド | 型 | 説明 |
|-----------|-----|------|
| `hintDirection` | `HintDirection?` | 現在表示すべきヒントの方向。nil = ヒント非表示 |

### 追加 enum

```swift
private enum HintDirection {
    case right   // 右スワイプ → 共有
    case left    // 左スワイプ → 興味なし
    case up      // 上スワイプ → スキップ
}
```

### 追加 computed property（@State 不要）

```swift
// ドラッグ距離から 0.0〜1.0 の不透明度を計算
private var hintOpacity: Double {
    switch hintDirection {
    case .right, .left: min(1.0, abs(horizontalOffset) / (hThreshold * 0.5))
    case .up:           min(1.0, abs(verticalOffset)   / (vThreshold * 0.5))
    case nil:           0.0
    }
}
```

---

## CardView の変更箇所サマリー

| 箇所 | 変更種別 | 内容 |
|------|---------|------|
| `@State` フィールド | 追加 | `hintDirection: HintDirection?` |
| `DragGesture.onChanged` | 更新 | 方向に応じて `hintDirection` を更新、5pt 未満は nil |
| `DragGesture.onEnded` | 更新 | `hintDirection = nil` に戻す（キャンセル・完了を問わず） |
| `flyOut()` | 更新 | フライアウト時に `hintDirection = nil` （フライアウト後はヒント不要） |
| View body | 追加 | `ZStack` の最上層に `ActionHintView` を重ねる |
| `ActionHintView` | 新規（`CardView` 内 private struct） | ヒントバッジを描画 |

---

## ActionHintView の構造

```text
ZStack（CardView 最上層）
└── if hintDirection != nil:
    HStack（アイコン + ラベル）
      ├── Image(systemName: ...)     // SF Symbol
      └── Text(...)                  // ラベル文字
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .background(Capsule, tinted color)
    .overlay(Capsule stroke)
    .opacity(hintOpacity)
    .padding(...)                    // カード内での位置調整
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: <方向依存>)
```

**配置アライメント**:
- `.right` → `.topLeading`（カード左上）
- `.left` → `.topTrailing`（カード右上）
- `.up` → `.top`（カード上端中央）
