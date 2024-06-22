import SwiftUI
import FirebaseFirestore

struct Category_View: View {
    var userId: String
    @State private var username = "Loading..."
    
    var body: some View {
        VStack {
            Text("Matches with \(username)")
                .font(.title)
                .padding(.top, 20)
                .onAppear {
                    fetchUsername(for: userId) { fetchedUsername in
                        self.username = fetchedUsername
                    }
                }
            VStack(spacing: 20) {
                NavigationLink(destination: MovieMatchView(userId: userId)) {
                    Text("View Movies")
                        .font(.body)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(LinearGradient(gradient: Gradient(colors: [Color.gradientTop, Color.gradientBottom]),
                                                   startPoint: .top,
                                                   endPoint: .bottom))
                        .cornerRadius(8)
                }
                
                NavigationLink(destination: tvMatchView(userId: userId)) {
                    Text("View TV Shows")
                        .foregroundColor(.white)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(LinearGradient(gradient: Gradient(colors: [Color.gradientTop, Color.gradientBottom]),
                                                   startPoint: .top,
                                                   endPoint: .bottom))
                        .cornerRadius(8)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .cornerRadius(16)
            .shadow(radius: 4)
            .padding()
            
            Spacer()
            
            
        }
    }
    
    private func fetchUsername(for friendID: String, completion: @escaping (String) -> Void) {
        let db = Firestore.firestore()
        let friendRef = db.collection("userProfiles").document(friendID)
        friendRef.getDocument { friendSnapshot, error in
            if let error = error {
                print("Error fetching friend document: \(error.localizedDescription)")
                completion("Unknown")
                return
            }
            guard let friendData = friendSnapshot?.data(),
                  let friendUsername = friendData["username"] as? String else {
                print("Friend data not found or username not available.")
                completion("Unknown")
                return
            }
            completion(friendUsername)
        }
    }
}

struct Category_View_Previews: PreviewProvider {
    static var previews: some View {
        Category_View(userId: "SampleUserID")
    }
}

