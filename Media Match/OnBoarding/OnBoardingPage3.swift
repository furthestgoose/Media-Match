import SwiftUI

struct OnBoardingPage3: View {
    @Binding var isFirstTime: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("Get Started With Media Match!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding()
            
            Text("To get the most out of Media Match, an account is required. This allows you to add friends, share your favorite media, and find content you both love.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            Spacer()
            
            Image(systemName: "person.crop.circle.fill.badge.checkmark")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .foregroundColor(.white)
                .padding()
            
            Spacer()
            
            Button(action: {
                UserDefaults.standard.set(true, forKey: "isFirstTime")
                isFirstTime = false
            }) {
                Text("Get Started")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnBoardingPage3(isFirstTime: .constant(true))
}

