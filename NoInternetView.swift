import SwiftUI

struct NoInternetView: View {
    var body: some View {
        VStack {
            Image(systemName: "wifi.exclamationmark")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.red)
            Text("No Internet Connection")
                .font(.largeTitle)
                .foregroundColor(.red)
                .padding()
            Text("Please check your internet connection and try again.")
                .font(.body)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
    }
}

