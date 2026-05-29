import SwiftUI

struct CardView: View {
    let article: Article
    let onSwipeRight: () -> Void
    let onSwipeLeft: () -> Void
    let onSkip: () -> Void

    @State private var horizontalOffset: CGFloat = 0
    @State private var verticalOffset: CGFloat = 0
    @State private var opacity: Double = 1

    private let hThreshold: CGFloat = UIScreen.main.bounds.width * 0.4
    private let vThreshold: CGFloat = 120

    var body: some View {
        ZStack(alignment: .topTrailing) {
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
                    } else {
                        horizontalOffset = w
                        verticalOffset = 0
                    }
                }
                .onEnded { value in
                    let w = value.translation.width
                    let h = value.translation.height
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
