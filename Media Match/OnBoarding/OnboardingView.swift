import SwiftUI

struct OnboardingView: View {
    @State private var currentTab = 0
    @Binding var isFirstTime: Bool
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 0.9, green: 0.2, blue: 0.2)]),
                           startPoint: .top,
                           endPoint: .bottom)
            .ignoresSafeArea()
            .opacity(0.5)
            TabView(selection: $currentTab,
                    content:  {
                        OnBoardingPage1()
                            .tag(0)
                        OnBoardingPage2()
                            .tag(1)
                        OnBoardingPage3(isFirstTime: $isFirstTime)
                            .tag(2)
                    })
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            .padding(.bottom, 40) // Add padding to the bottom to push the dots up
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(isFirstTime: .constant(true))
    }
}
