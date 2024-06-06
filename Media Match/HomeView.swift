import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SDWebImage

struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    @State private var userProfile: UserProfile?
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isUploading = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if let profile = userProfile {
                    NavigationLink(destination: UserProfileView()) {
                        VStack {
                            if let imageUrl = profile.profilePictureURL, let url = URL(string: imageUrl), !imageUrl.isEmpty {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 50, height: 50)
                                            .clipShape(Circle())
                                    case .failure(_):
                                        Image("default-profile")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 50, height: 50)
                                            .clipShape(Circle())
                                    case .empty:
                                        ProgressView()
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            } else {
                                Image("default-profile")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            }
                            Text("Profile")
                                .font(.caption)
                                .opacity(0.8)
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity, alignment: .topTrailing) // Ensure image is in top right
                        .padding(.trailing) // Add some trailing padding for spacing
                    }
                } else {
                    ProgressView()
                }
                
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Browse Content")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                            .padding(.bottom)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 20) {
                                NavigationLink(destination: MovieBrowse()) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(LinearGradient(gradient: Gradient(colors: [Color.gradientTop, Color.gradientBottom]),
                                                                 startPoint: .top,
                                                                 endPoint: .bottom))
                                            .frame(width: 300, height: 150)
                                        
                                        VStack {
                                            Image(systemName: "film")
                                                .resizable()
                                                .foregroundColor(.white)
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 100, height: 100)
                                            Text("Movies")
                                                .font(.body)
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .frame(width: 300, height: 150) // Ensure each card has fixed width and height
                                }
                                
                                NavigationLink(destination: TvBrowse()) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(LinearGradient(gradient: Gradient(colors: [Color.gradientTop, Color.gradientBottom]),
                                                                 startPoint: .top,
                                                                 endPoint: .bottom))
                                            .frame(width: 300, height: 150)
                                        
                                        VStack {
                                            Image(systemName: "tv")
                                                .resizable()
                                                .foregroundColor(.white)
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 100, height: 100)
                                            Text("TV Shows")
                                                .font(.body)
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .frame(width: 300, height: 150) // Ensure each card has fixed width and height
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20) // Adjusted padding to horizontal
                            .padding(.top)
                            .padding(.bottom, 20)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal) // Remove unnecessary padding
                }
                .background(Color.clear) // Set background color to transparent
            }
            .onAppear {
                fetchUserProfile()
            }
        }
    }
    
    private func fetchUserProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("userProfiles").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user profile: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data() else { return }
            
            let profile = UserProfile(
                userId: data["userId"] as? String ?? "",
                username: data["username"] as? String ?? "",
                profilePictureURL: data["profilePictureURL"] as? String ?? "",
                likedItems: data["likedItems"] as? [String] ?? [],
                friends: data["friends"] as? [String] ?? []
            )
            self.userProfile = profile
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}


