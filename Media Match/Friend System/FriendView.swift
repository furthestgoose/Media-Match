import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SDWebImage

class FriendViewModel: ObservableObject {
    @Published var incomingRequests: [UserProfile] = []
    @Published var outgoingRequests: [UserProfile] = []
    @Published var friends: [UserProfile] = []

    func loadIncomingRequests() {
        FriendService.shared.loadIncomingRequests { incomingRequests in
            self.incomingRequests = incomingRequests
        }
    }

    func loadOutgoingRequests() {
        FriendService.shared.loadOutgoingRequests { outgoingRequests in
            self.outgoingRequests = outgoingRequests
        }
    }
    
    func loadFriends() {
            FriendService.shared.loadFriends { friends in
                self.friends = friends
            }
        }
}

struct FriendView: View {
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
        ZStack {
            Color.theme
                .ignoresSafeArea()
            VStack {
                Form {
                    Section(header: Text("Add Friends")) {
                        TextField("Search", text: $friendSearch)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                                .autocapitalization(.none)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(exists ? Color.clear : Color.red, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .onChange(of: friendSearch) { searchText in
                                    if !searchText.isEmpty {
                                        searchForFriend()
                                    } else {
                                        exists = true
                                    }
                                }

                        if !exists {
                            Text("User does not exist")
                                .foregroundColor(.red)
                                .font(.footnote)
                                .padding(.top, 2)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                        }
                    }

                    if isFriendFound, let profile = foundUserProfile, let currentUserProfile = currentUserProfile {
                        Section(header: Text("User Found")) {
                            HStack {
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
                                VStack(alignment: .leading) {
                                    Text(profile.username)
                                        .font(.headline)
                                }
                                Spacer()
                                if !friends.contains(where: { $0.userId == profile.userId }) && !outgoingRequests.contains(where: { $0.userId == profile.userId }) {
                                    Button("Add Friend") {
                                        sendFriendRequest(to: profile.userId)
                                        loadFriendRequests()
                                        friendSearch = ""
                                        isFriendFound = false
                                    }
                                    .disabled(currentUserProfile != nil && (friendSearch.lowercased() == (currentUserProfile.username.lowercased()) || friendSearch.isEmpty))
                                } else {
                                    Text("Already requested/friends")
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                }

                            }
                        }
                    }

                    Section(header: Text("Requests")) {
                        if incomingRequests.isEmpty && outgoingRequests.isEmpty {
                            Text("No incoming or outgoing requests")
                                .foregroundColor(.gray)
                                .font(.footnote)
                        } else {
                            ForEach(incomingRequests + outgoingRequests, id: \.userId) { userProfile in
                                HStack {
                                    if let imageUrl = userProfile.profilePictureURL, let url = URL(string: imageUrl) {
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
                                    Text(userProfile.username)
                                        .font(.headline)
                                    Spacer()
                                    if incomingRequests.contains(where: { $0.userId == userProfile.userId }) {
                                        HStack {
                                            Button("Accept") {
                                                acceptFriendRequest(from: userProfile.userId)
                                                loadFriends()
                                            }
                                            .foregroundColor(.green)
                                            .tint(.green)
                                            Button("Decline") {
                                                declineFriendRequest(from: userProfile.userId)
                                            }
                                            .foregroundColor(.red)
                                            .tint(.pink)
                                        }
                                        .buttonStyle(.bordered)
                                    } else {
                                        Text("Pending")
                                            .opacity(0.5)
                                    }
                                }
                            }
                        }
                    }

                    Section(header: Text("Friends")) {
                        if friends.isEmpty {
                            Text("No friends yet")
                                .foregroundColor(.gray)
                                .font(.footnote)
                        } else {
                            ForEach(friends, id: \.userId) { friend in
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
                                    if !friends.isEmpty {
                                        HStack {
                                            Button("Delete") {
                                                deleteFriend(userId: friend.userId)
                                                loadFriendRequests()
                                                loadFriends()
                                            }
                                            .foregroundColor(.red)
                                            .tint(.pink)
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            loadFriendRequests()
            loadCurrentUserProfile()
            loadFriends()
        }
        .onReceive(friendViewModel.$incomingRequests) { incomingRequests in
            self.incomingRequests = incomingRequests
        }
        .onReceive(friendViewModel.$outgoingRequests) { outgoingRequests in
            self.outgoingRequests = outgoingRequests
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

    func searchForFriend() {
        isLoading = true
        FriendService.shared.searchForFriend(username: friendSearch) { result in
            isLoading = false
            switch result {
            case .success(let profile):
                self.foundUserProfile = profile
                self.isFriendFound = true
                self.exists = true
            case .failure(let error):
                print("Error searching for friend: \(error.localizedDescription)")
                self.isFriendFound = false
                self.exists = false
            }
        }
    }

    func loadFriendRequests() {
        isLoading = true

        var incomingRequestsLoaded = false
        var outgoingRequestsLoaded = false

        friendViewModel.loadIncomingRequests()
        FriendService.shared.loadIncomingRequests { incomingRequests in
            print("Incoming requests loaded:", incomingRequests)
            self.incomingRequests = incomingRequests
            incomingRequestsLoaded = true
            checkLoadingState()
        }

        friendViewModel.loadOutgoingRequests()
        FriendService.shared.loadOutgoingRequests { outgoingRequests in
            print("Outgoing requests loaded:", outgoingRequests)
            self.outgoingRequests = outgoingRequests
            outgoingRequestsLoaded = true
            checkLoadingState()
        }

        func checkLoadingState() {
            if incomingRequestsLoaded && outgoingRequestsLoaded {
                isLoading = false
            }
        }
    }

    func loadFriends() {
        friendViewModel.loadFriends()
    }

    func sendFriendRequest(to userId: String) {
        print("Sending friend request to user ID:", userId)
        FriendService.shared.sendFriendRequest(to: userId) { error in
            if let error = error {
                print("Error sending friend request: \(error.localizedDescription)")
            } else {
                print("Friend request sent successfully")
            }
        }
    }

    func acceptFriendRequest(from userId: String) {
        print("Accepting friend request from user ID:", userId)
        FriendService.shared.acceptFriendRequest(from: userId) { error in
            if let error = error {
                print("Error accepting friend request: \(error.localizedDescription)")
            } else {
                print("Friend request accepted successfully")
                if let index = self.incomingRequests.firstIndex(where: { $0.userId == userId }) {
                    let acceptedFriend = self.incomingRequests.remove(at: index)
                    self.friends.append(acceptedFriend)
                }
            }
        }
    }

    func declineFriendRequest(from userId: String) {
        print("Declining friend request from user ID:", userId)
        FriendService.shared.declineFriendRequest(from: userId) { error in
            if let error = error {
                print("Error declining friend request: \(error.localizedDescription)")
            } else {
                print("Friend request declined successfully")
                removeIncomingRequest(userId: userId)
            }
        }
    }

    func removeIncomingRequest(userId: String) {
        if let index = incomingRequests.firstIndex(where: { $0.userId == userId }) {
            incomingRequests.remove(at: index)
        }
    }
    
    func deleteFriend(userId: String) {
        FriendService.shared.removeFriend(userId: userId) { error in
            if let error = error {
                print("Error removing friend: \(error.localizedDescription)")
            } else {
                print("Friend removed successfully")
                if let index = self.friends.firstIndex(where: { $0.userId == userId }) {
                    self.friends.remove(at: index)
                }
                if let currentUserProfile = self.currentUserProfile, let index = currentUserProfile.friends.firstIndex(of: userId) {
                    self.currentUserProfile?.friends.remove(at: index)
                }
            }
        }
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
