//
//  MainView.swift
//  Media Match
//
//  Created by Adam Byford on 02/06/2024.
//

import SwiftUI

struct MainView: View {
    var body: some View {
            TabView {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .toolbarBackground(.visible, for: .tabBar)
                    .toolbarBackground(LinearGradient(gradient: Gradient(colors: [Color.gradientTop, Color.gradientBottom]),
                                                       startPoint: .leading,
                                                      endPoint: .trailing).opacity(0.8), for: .tabBar)
                FriendView()
                    .tabItem {
                        Label("Friends", systemImage: "person.2.fill")
                    }
                    .toolbarBackground(.visible, for: .tabBar)
                    .toolbarBackground(LinearGradient(gradient: Gradient(colors: [Color.gradientTop, Color.gradientBottom]),
                                                       startPoint: .leading,
                                                      endPoint: .trailing).opacity(0.8), for: .tabBar)
                MatchView()
                    .tabItem {
                        Label("Matches", systemImage: "heart.circle")
                    }
                    .toolbarBackground(.visible, for: .tabBar)
                    .toolbarBackground(LinearGradient(gradient: Gradient(colors: [Color.gradientTop, Color.gradientBottom]),
                                                       startPoint: .leading,
                                                      endPoint: .trailing).opacity(0.8), for: .tabBar)
            }
        }
}

#Preview {
    MainView()
}
