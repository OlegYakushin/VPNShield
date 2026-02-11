//
//  VPNActivityManager..swift
//  VPNShield
//
//  Created by Oleg Yakushin on 31/7/25.
//

import Foundation
import ActivityKit

@MainActor
final class VPNActivityManager {
    static let shared = VPNActivityManager()
    private var activity: Activity<VPNActivityAttributes>?

    /// Подцепиться к уже живой Live Activity при запуске/возврате в приложение
    func attachIfExists() {
        guard #available(iOS 16.1, *) else { return }
        activity = Activity<VPNActivityAttributes>.activities.first
    }

    func start(serverName: String) {
        guard #available(iOS 16.1, *) else {
            print("Live Activities not available on this OS")
            return
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // Если уже есть активность — просто обновим
        if let existing = Activity<VPNActivityAttributes>.activities.first {
            activity = existing
            Task { await update(serverName: serverName, isConnected: true) }
            return
        }

        let attrs = VPNActivityAttributes(serviceName: "VPN ЩИТ")
        let state = VPNActivityAttributes.ContentState(
            isConnected: true,
            serverName: serverName,
            startedAt: Date()
        )

        do {
            activity = try Activity.request(attributes: attrs, contentState: state, pushType: nil)
        } catch {
            print("Failed to start Live Activity:", error)
        }
    }

    func update(serverName: String? = nil, isConnected: Bool? = nil) async {
        guard #available(iOS 16.1, *), let activity else { return }
        var newState = activity.contentState
        if let s = serverName { newState.serverName = s }
        if let c = isConnected { newState.isConnected = c }
        await activity.update(using: newState)
    }

    func stop(immediately: Bool = true) async {
        guard #available(iOS 16.1, *), let activity else { return }
        await activity.end(dismissalPolicy: immediately ? .immediate : .default)
        self.activity = nil
    }
}
