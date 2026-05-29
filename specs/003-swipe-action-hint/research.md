# Research: スワイプアクションヒント

**Branch**: `003-swipe-action-hint` | **Date**: 2026-05-29

---

## 1. ヒントの配置パターン

**Decision**: **カード左上（右スワイプ）／右上（左スワイプ）／上端中央（上スワイプ）** にバッジ形式で表示する

**Rationale**:
- Tinder・Bumble などのスワイプアプリの標準パターン
- カードの主要コンテンツ（タイトル・概要）を覆わない
- スワイプ方向と表示位置が一致するため直感的（右に動かすと左上にバッジ → 「右に行くとこうなる」）
- FR-007「コンテンツの視認性を著しく損ねない」を満たす

**Alternatives considered**:
- 中央大型オーバーレイ → コンテンツが見えなくなる、FR-007 違反
- カード下部 → スワイプ方向と位置関係が直感的でない

---

## 2. ヒントの不透明度計算

**Decision**: `opacity = min(1.0, abs(offset) / (threshold * 0.5))` — 閾値の50%で完全表示

**Rationale**:
- 5pt 以下ではほぼ不可視（FR-003 の意図を自然に満たす）
- 閾値の50%（≒ hThreshold*0.5 = 画面幅×20% ≈ 80〜90pt）で完全表示
- 確定閾値 100% に達する前に十分な視認性を確保（P2 の "75% 以上ではっきり" と整合）
- 閾値の50%より先は opacity = 1.0 で固定（それ以上引っ張っても変化しない方が安定感がある）

---

## 3. 方向の判定タイミング

**Decision**: 既存の `DragGesture.onChanged` 内で `horizontalOffset`/`verticalOffset` を更新するタイミングで同時に `hintDirection` を更新する

**Rationale**:
- `onChanged` はドラッグごとに呼ばれるため、リアルタイムにヒントを更新できる
- 既存の方向判定ロジック（`abs(h) > abs(w)` で縦横優先判定）を流用できる

---

## 4. ヒントのビジュアルデザイン

**Decision**: SF Symbols アイコン＋短いラベルを角丸のバッジ（`Capsule`）に入れ、ストローク枠付きで表示する

| 方向 | アイコン | ラベル | カラー |
|------|---------|-------|--------|
| 右（共有） | `square.and.arrow.up` | 共有 | 緑（`.green`） |
| 左（興味なし） | `hand.thumbsdown` | 興味なし | 赤（`.red`） |
| 上（スキップ） | `forward.end` | スキップ | グレー（`.secondary`） |

**Rationale**:
- カラーコーディングで瞬時に認識できる（緑=肯定、赤=否定、グレー=中立）
- `Capsule` バッジは iOS のシステム UI で広く使われるパターン
- ストローク枠がカード背景色に関わらず視認性を確保

---

## 5. 状態管理

**Decision**: `CardView` に `@State var hintDirection: HintDirection?` を1つだけ追加する

**Rationale**:
- `horizontalOffset`・`verticalOffset` は既存の状態。ヒント用に別途オフセットを計算する必要はなく、両変数から方向・距離を導出できる
- `hintOpacity` は `hintDirection` と既存オフセット値から `var` で計算（`@State` 不要）
- 外部から `hintDirection` を参照する必要はないため `private`

```swift
enum HintDirection { case right, left, up }

private var hintOpacity: Double {
    switch hintDirection {
    case .right:  min(1.0, abs(horizontalOffset) / (hThreshold * 0.5))
    case .left:   min(1.0, abs(horizontalOffset) / (hThreshold * 0.5))
    case .up:     min(1.0, abs(verticalOffset)   / (vThreshold * 0.5))
    case nil:     0
    }
}
```
