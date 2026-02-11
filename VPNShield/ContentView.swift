//
//  ContentView.swift
//  VPNShield
//
//  Created by Oleg Yakushin on 11/7/25.
//

import SwiftUI

struct ContentView: View {
        var body: some View {
            TabView {
                HomeView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Главная")
                    }

                SupportView()
                    .tabItem {
                        Image(systemName: "headphones")
                        Text("Поддержка")
                    }

                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape")
                        Text("Настройки")
                    }
            }
            .accentColor(.green)
        }
    }


#Preview {
    ContentView()
}
