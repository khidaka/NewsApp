import SwiftUI

struct CardView: View {
    let article: Article
    let onSwipeRight: () -> Void
    let onSwipeLeft: () -> Void
    let onSkip: () -> Void

    @State private var horizontalOffset: CGFloat = 0
    @State private var verticalOffset: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var hintDirection: HintDirection? = nil

    private let hThreshold: CGFloat = UIScreen.main.bounds.width * 0.4
    private let vThreshold: CGFloat = 120
    private let minHintDistance: CGFloat = 5

    private var hintOpacity: Double {
        switch hintDirection {
        case .right, .left:
            let d = abs(horizontalOffset)
            guard d >= minHintDistance else { return 0 }
            return min(1.0, d / (hThreshold * 0.5))
        case .up:
            let d = abs(verticalOffset)
            guard d >= minHintDistance else { return 0 }
            return min(1.0, d / (vThreshold * 0.5))
        case nil:
            return 0
        }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // カード本体
            VStack(alignment: .leading, spacing: 12) {
                Text(article.sourceName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(article.title)
                    .font(.headline)
                    .lineLimit(3)

                Text(article.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(5)

                Spacer()

                Text(article.fetchedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: 280, alignment: .topLeading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)

            // スキップボタン（右上）
            Button {
                flyOut(direction: .up)
                onSkip()
            } label: {
                Image(systemName: "forward.end")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("スキップ")

            // アクションヒントバッジ
            if let direction = hintDirection {
                ActionHintView(direction: direction)
                    .opacity(hintOpacity)
                    .frame(maxWidth: .infinity, maxHeight: 280, alignment: direction.alignment)
                    .padding(12)
                    .allowsHitTesting(false)
            }
        }
        .offset(x: horizontalOffset, y: verticalOffset)
        .rotationEffect(.degrees(Double(horizontalOffset) / 20))
        .opacity(opacity)
        .gesture(
            DragGesture()
                .onChanged { value in
                    let w = value.translation.width
                    let h = value.translation.height
                    if abs(h) > abs(w) {
                        verticalOffset = min(0, h)
                        horizontalOffset = 0
                        hintDirection = abs(h) >= minHintDistance ? .up : nil
                    } else {
                        horizontalOffset = w
                        verticalOffset = 0
                        if abs(w) >= minHintDistance {
                            hintDirection = w > 0 ? .right : .left
                        } else {
                            hintDirection = nil
                        }
                    }
                }
                .onEnded { value in
                    let w = value.translation.width
                    let h = value.translation.height
                    hintDirection = nil
                    if abs(h) > abs(w) && h < -vThreshold {
                        flyOut(direction: .up)
                        onSkip()
                    } else if w > hThreshold {
                        flyOut(direction: .right)
                        onSwipeRight()
                    } else if w < -hThreshold {
                        flyOut(direction: .left)
                        onSwipeLeft()
                    } else {
                        withAnimation(.spring()) {
                            horizontalOffset = 0
                            verticalOffset = 0
                        }
                    }
                }
        )
        .accessibilityLabel("\(article.sourceName): \(article.title)")
        .accessibilityHint("右にスワイプして共有、左にスワイプして興味なし、上にスワイプしてスキップ")
    }

    private enum Direction { case right, left, up }

    private func flyOut(direction: Direction) {
        hintDirection = nil
        withAnimation(.easeOut(duration: 0.3)) {
            switch direction {
            case .right: horizontalOffset = 600
            case .left:  horizontalOffset = -600
            case .up:    verticalOffset = -800
            }
            opacity = 0
        }
    }
}

// MARK: - HintDirection

private enum HintDirection {
    case right, left, up

    var alignment: Alignment {
        switch self {
        case .right: .topLeading
        case .left:  .topTrailing
        case .up:    .top
        }
    }

    var icon: String {
        switch self {
        case .right: "square.and.arrow.up"
        case .left:  "hand.thumbsdown"
        case .up:    "forward.end"
        }
    }

    var label: String {
        switch self {
        case .right: "共有"
        case .left:  "興味なし"
        case .up:    "スキップ"
        }
    }

    var color: Color {
        switch self {
        case .right: .green
        case .left:  .red
        case .up:    .secondary
        }
    }
}

// MARK: - ActionHintView

private struct ActionHintView: View {
    let direction: HintDirection

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: direction.icon)
                .font(.system(size: 14, weight: .bold))
            Text(direction.label)
                .font(.system(size: 14, weight: .bold))
        }
        .foregroundStyle(direction.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(direction.color.opacity(0.15))
                .overlay(
                    Capsule()
                        .strokeBorder(direction.color, lineWidth: 2)
                )
        )
    }
}
