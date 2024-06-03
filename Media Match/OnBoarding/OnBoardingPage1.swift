import SwiftUI

struct OnBoardingPage1: View {
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                Image(systemName: "figure.2.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .foregroundColor(.white)
                    .padding()
                
                Text("Welcome to Media Match!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("Connect with your friends and discover content you both love. Add friends, share your favorite media, and find perfect matches for your next movie night.")
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

#Preview {
    OnBoardingPage1()
}

