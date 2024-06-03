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
                            Label("Browse", systemImage: "doc.text.magnifyingglass")
                        }

                    FriendView()
                        .tabItem {
                            Label("Friends", systemImage: "person.2.fill")
                        }
                    MatchView()
                        .tabItem{
                            Label("Matches", systemImage: "heart.circle")
                        }
                }
    }
}

#Preview {
    MainView()
}
