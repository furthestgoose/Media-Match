import SwiftUI
import FirebaseAuth

struct StartView: View {
    @EnvironmentObject var authService: AuthService
    @State private var isFirstTime: Bool = UserDefaults.standard.bool(forKey: "isFirstTime") == false
    
    var body: some View {
        if isFirstTime {
            OnboardingView(isFirstTime: $isFirstTime)
        } else if authService.signedIn {
            MainView()
        } else {
            WelcomeView()
        }
    }
}

struct StartView_Previews: PreviewProvider {
    @StateObject static var authService = AuthService()

    static var previews: some View {
        StartView().environmentObject(authService)
    }
}

