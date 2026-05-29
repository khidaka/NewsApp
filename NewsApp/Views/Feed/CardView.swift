import SwiftUI

struct CardView: View {
    let article: Article
    let onSwipeRight: () -> Void
    let onSwipeLeft: () -> Void

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1

    private let swipeThreshold: CGFloat = UIScreen.main.bounds.width * 0.4

    var body: some View {
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
        .offset(x: offset)
        .rotationEffect(.degrees(Double(offset) / 20))
        .opacity(opacity)
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = value.translation.width
                }
                .onEnded { value in
                    let translation = value.translation.width
                    if translation > swipeThreshold {
                        flyOut(to: .right)
                        onSwipeRight()
                    } else if translation < -swipeThreshold {
                        flyOut(to: .left)
                        onSwipeLeft()
                    } else {
                        withAnimation(.spring()) { offset = 0 }
                    }
                }
        )
        .accessibilityLabel("\(article.sourceName): \(article.title)")
        .accessibilityHint("右にスワイプして共有、左にスワイプして興味なし")
    }

    private enum SwipeSide { case right, left }

    private func flyOut(to side: SwipeSide) {
        let destination: CGFloat = side == .right ? 600 : -600
        withAnimation(.easeOut(duration: 0.3)) {
            offset = destination
            opacity = 0
        }
    }
}
