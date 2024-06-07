import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SDWebImage

struct Match_Home_View: View {
    @State private var friendSearch: String = ""
    @State private var isFriendFound: Bool = false
    @State private var foundUserProfile: UserProfile?
    @State private var exists: Bool = true
    @State private var incomingRequests: [UserProfile] = []
    @State private var outgoingRequests: [UserProfile] = []
    @State private var friends: [UserProfile] = []
    @State private var isLoading: Bool = false
    @State private var currentUserProfile: UserProfile?
    @StateObject private var friendViewModel = FriendViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme
                    .ignoresSafeArea()
                VStack {
                    Form {
                        Section(header: Text("Friends")) {
                            if friends.isEmpty {
                                Text("No friends yet")
                                    .foregroundColor(.gray)
                                    .font(.footnote)
                            } else {
                                ForEach(friends, id: \.userId) { friend in
                                    NavigationLink(destination: Category_View(userId: friend.userId)) {
                                        HStack {
                                            if let imageUrl = friend.profilePictureURL, let url = URL(string: imageUrl) {
                                                AsyncImage(url: url) { phase in
                                                    switch phase {
                                                    case .success(let image):
                                                        image
                                                            .resizable()
                                                            .scaledToFill()
                                                            .frame(width: 50, height: 50)
                                                            .clipShape(Circle())
                                                    case .failure(_):
                                                        Image(systemName: "person.crop.circle.badge.exclamationmark")
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
                                                Image(systemName: "person.crop.circle")
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 50, height: 50)
                                                    .clipShape(Circle())
                                            }
                                            Text(friend.username)
                                                .font(.headline)
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .onAppear {
                loadCurrentUserProfile()
                loadFriends()
            }
            .onReceive(friendViewModel.$friends) { friends in
                self.friends = friends
            }
            .overlay(
                Group {
                    if isLoading {
                        ProgressView()
                    }
                }
            )
        }
    }

    func loadFriends() {
        friendViewModel.loadFriends()
    }

    private func checkLoadingState() {
        if !incomingRequests.isEmpty || !outgoingRequests.isEmpty {
            isLoading = false
        }
    }

    private func loadCurrentUserProfile() {
        isLoading = true
        if let currentUserID = Auth.auth().currentUser?.uid {
            FriendService.shared.loadUserProfile(for: currentUserID) { profile in
                isLoading = false
                if let profile = profile {
                    self.currentUserProfile = profile
                }
            }
        }
    }
}

