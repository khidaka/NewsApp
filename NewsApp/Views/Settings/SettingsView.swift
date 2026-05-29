import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("ニュースソース") {
                    SourceListView()
                }
                NavigationLink("Obsidian Vault") {
                    VaultPickerView()
                }
            }
            .navigationTitle("設定")
        }
    }
}
