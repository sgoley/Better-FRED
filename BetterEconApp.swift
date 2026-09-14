import BackgroundTasks
import SwiftUI
import UserNotifications

@MainActor
final class AppNavigationCoordinator: ObservableObject {
    static let shared = AppNavigationCoordinator()

    enum Tab: Hashable {
        case overview
        case explore
        case compare
        case saved
        case settings
    }

    @Published var selectedTab: Tab = .overview
    @Published var pendingSeriesID: String?

    func openAlert(for seriesID: String) {
        selectedTab = .saved
        pendingSeriesID = seriesID
    }
}

final class AlertNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }
        guard let seriesID = response.notification.request.content.userInfo["seriesID"] as? String else { return }
        Task { @MainActor in
            AppNavigationCoordinator.shared.openAlert(for: seriesID)
        }
    }
}

@MainActor
final class AlertBackgroundScheduler {
    static let shared = AlertBackgroundScheduler()
    static let identifier = "com.betterecon.app.alert-refresh"

    private var evaluator: (() async -> Bool)?

    static func registerTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            Task { @MainActor in
                AlertBackgroundScheduler.shared.handle(refreshTask)
            }
        }
    }

    func setEvaluator(_ evaluator: @escaping () async -> Bool) {
        self.evaluator = evaluator
    }

    func scheduleIfNeeded(hasActiveRules: Bool) {
        guard hasActiveRules else { return }
        let request = BGAppRefreshTaskRequest(identifier: Self.identifier)
        // iOS chooses the exact time. A modest requested cadence preserves battery
        // while ensuring a background opportunity is always queued.
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private func handle(_ task: BGAppRefreshTask) {
        // Queue the next opportunity before beginning work, as required by the
        // background-task lifecycle.
        scheduleIfNeeded(hasActiveRules: true)
        let work = Task { @MainActor [weak self] in
            guard !Task.isCancelled else {
                task.setTaskCompleted(success: false)
                return
            }
            let success = await self?.evaluator?() ?? false
            task.setTaskCompleted(success: success && !Task.isCancelled)
        }
        task.expirationHandler = { work.cancel() }
    }
}

@main
struct BetterEconApp: App {
    @StateObject private var appModel = AppModel()
    private let notificationDelegate = AlertNotificationDelegate()

    init() {
        AlertBackgroundScheduler.registerTask()
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appModel)
                .environmentObject(AppNavigationCoordinator.shared)
        }
    }
}
