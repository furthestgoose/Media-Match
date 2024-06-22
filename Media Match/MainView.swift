import SwiftUI
import Network
import GoogleMobileAds

struct MainView: View {
    @ObservedObject private var networkMonitor = NetworkMonitor()
    var body: some View {
        VStack(spacing: 0) {
            AdBannerViewController()
                            .frame(height: 100)
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
                Match_Home_View()
                    .tabItem {
                        Label("Matches", systemImage: "heart.circle")
                    }
                    .toolbarBackground(.visible, for: .tabBar)
                    .toolbarBackground(LinearGradient(gradient: Gradient(colors: [Color.gradientTop, Color.gradientBottom]),
                                                      startPoint: .leading,
                                                      endPoint: .trailing).opacity(0.8), for: .tabBar)
            }
            .disabled(!networkMonitor.isConnected)
            .noInternetOverlay()
        }
    }
        
}

#Preview {
    MainView()
}
