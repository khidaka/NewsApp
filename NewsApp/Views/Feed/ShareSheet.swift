import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    let title: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: [url, title],
            applicationActivities: nil
        )
    }

    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}
