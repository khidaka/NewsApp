import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct NewsAppApp: App {

    @State private var obsidianContext: ObsidianContext? = nil
    private let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Article.self, NewsSource.self, InterestSignal.self)
        } catch {
            fatalError("SwiftData container の初期化に失敗しました: \(error)")
        }
        registerBackgroundTask()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environment(\.obsidianContext, obsidianContext)
                .task { await loadObsidianContext() }
        }
    }

    // MARK: - Obsidian

    @MainActor
    private func loadObsidianContext() async {
        guard let data = UserDefaults.standard.data(forKey: ObsidianReaderService.bookmarkKey) else { return }
        let service = ObsidianReaderService()
        do {
            let keywords = try await service.extractKeywords(from: data)
            obsidianContext = ObsidianContext(keywords: keywords, lastScannedAt: .now)
        } catch {
            // Obsidian アクセス失敗時はシグナルなしで継続
        }
    }

    // MARK: - Background fetch

    private func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.newsapp.refresh",
            using: nil
        ) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
    }

    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        scheduleNextBackgroundFetch()
        let context = ModelContext(container)
        let service = NewsCollectorService()
        Task {
            do {
                _ = try await service.fetchAll(context: context, obsidianContext: obsidianContext)
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }
        task.expirationHandler = { task.setTaskCompleted(success: false) }
    }

    private func scheduleNextBackgroundFetch() {
        let request = BGAppRefreshTaskRequest(identifier: "com.newsapp.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600)
        try? BGTaskScheduler.shared.submit(request)
    }
}

// MARK: - Environment key

private struct ObsidianContextKey: EnvironmentKey {
    static let defaultValue: ObsidianContext? = nil
}

extension EnvironmentValues {
    var obsidianContext: ObsidianContext? {
        get { self[ObsidianContextKey.self] }
        set { self[ObsidianContextKey.self] = newValue }
    }
}
