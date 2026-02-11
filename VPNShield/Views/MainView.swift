//
//  MainView.swift
//  VPNShield
//
//  Created by Oleg Yakushin on 14/7/25.
//

import SwiftUI

struct MainView: View {
    @AppStorage("showOnboarding") var showOnboarding: Bool = true
    var body: some View {
        ZStack {
       

            if showOnboarding {
                OnboardingView()
                    .ignoresSafeArea()
                    .zIndex(1)
            } else {
                ContentView()
            }
        }
    }
}

#Preview { MainView() }
