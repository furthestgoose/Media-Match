import SwiftUI

struct OnBoardingPage2: View {
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                Text("Discover Amazing Features")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                FeatureView(
                    iconName: "person.2.fill",
                    featureTitle: "Add Friends",
                    featureDescription: "Easily add your friends to share and enjoy media together."
                )
                
                FeatureView(
                    iconName: "heart.fill",
                    featureTitle: "Find Matches",
                    featureDescription: "Discover content you and your friends both love to watch."
                )
                
                FeatureView(
                    iconName: "globe",
                    featureTitle: "Filter by Region & Service",
                    featureDescription: "Filter content based on your region and preferred streaming services."
                )
                
                Spacer()
            }
            .padding()
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

#Preview {
    OnBoardingPage2()
}

