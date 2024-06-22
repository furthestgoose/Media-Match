import SwiftUI

struct IntroductionView: View {
    var onDismiss: () -> Void
    
    var body: some View {
        Color.white.opacity(0.8)
            .overlay(
                ZStack {
                    HStack {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.title)
                            .foregroundColor(.red)
                        Text("Swipe Left to Dislike")
                            .font(.body)
                            .foregroundColor(.black)
                        Divider()
                            .frame(width: 1, height: .infinity)
                        .background(Color.black)
                        .padding()
                        Text("Swipe Right to Like")
                            .font(.body)
                            .foregroundColor(.black)
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                    }
                }
            )
            .toolbar(.hidden, for: .tabBar)
            .contentShape(Rectangle())
            .onTapGesture {
                onDismiss()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
