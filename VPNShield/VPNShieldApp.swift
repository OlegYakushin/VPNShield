//
//  VPNShieldApp.swift
//  VPNShield
//
//  Created by Oleg Yakushin on 11/7/25.
//

import SwiftUI


@main
struct VPNShieldApp: App {
    @Environment(\.openURL) private var openURL

    init() {
        VPNActivityManager.shared.attachIfExists()
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    if url.host == "disconnect" {
                        Task { await VPNActivityManager.shared.stop() }
                    }
                }
        }
    }
}

