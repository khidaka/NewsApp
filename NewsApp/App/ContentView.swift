import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            FeedView()
                .tabItem {
                    Label("ニュース", systemImage: "newspaper")
                }
            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
        }
    }
}
