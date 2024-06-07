import SwiftUI

struct NoInternetOverlayModifier: ViewModifier {
    @EnvironmentObject var networkMonitor: NetworkMonitor

    func body(content: Content) -> some View {
        ZStack {
            content
            if !networkMonitor.isConnected {
                NoInternetView()
                    .background(Color.white)
                    .edgesIgnoringSafeArea(.all)
            }
        }
    }
}

extension View {
    func noInternetOverlay() -> some View {
        self.modifier(NoInternetOverlayModifier())
    }
}

