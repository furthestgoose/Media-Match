import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ShowDetails: Codable {
    let id: Int
    let name: String
    let overview: String
    var posterPath: String?
    var matchedFriendUsername: String?
    var firstAirDate: String?
    var voteAverage: Double?
    var ageRating: String?
}

struct tvMatchView: View {
    var userId: String
    @State private var userID: String? 
    @State private var friendIDs: [String]?
    @State private var matchedShows: [ShowDetails] = []
    @State private var isLoading = false
    @State private var hasFetchedData = false

    var body: some View {
        GeometryReader { geometry in
            let isIPad = geometry.size.width >= 748
            let scale = isIPad ? 1.5 : 1.0
            VStack {
                if isLoading {
                    ProgressView()
                        .padding()
                } else if matchedShows.isEmpty {
                    Text("No Movie matches found")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(matchedShows, id: \.id) { show in
                                ShowDetailView(show: show)
                            }
                        }
                        .padding()
                    }
                }
            }
            .padding(.top,isIPad ? geometry.size.height * 0.10 : 0)
            .frame(
                width: isIPad ? geometry.size.width * 0.8 : geometry.size.width,
                height: isIPad ? geometry.size.height * 0.8 : geometry.size.height
            )
            .scaleEffect(scale)
            .position(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2
            )
        }
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            if !hasFetchedData {
                fetchUserData()
                hasFetchedData = true
            }
        }
    }
    
    
    private func fetchUserData() {
        isLoading = true
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User ID not found")
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("userProfiles").document(userID)
        userRef.getDocument { userSnapshot, error in
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
                isLoading = false
                return
            }
            guard let userData = userSnapshot?.data() else {
                print("User data not found")
                isLoading = false
                return
            }
            
            self.userID = userID
            self.friendIDs = userData["friends"] as? [String]
            
            if let likedItems = userData["likedShows"] as? [Int], let friendIDs = self.friendIDs {
                findMatchedShows(userID: userID, likedItems: likedItems, friendIDs: friendIDs) {
                    self.isLoading = false
                }
            } else {
                self.isLoading = false
            }
        }
    }
    
    private func findMatchedShows(userID: String, likedItems: [Int], friendIDs: [String], completion: @escaping () -> Void) {
        var matchedShowIDs: [Int: [String]] = [:]
        let dispatchGroup = DispatchGroup()
        
        for friendID in friendIDs {
            dispatchGroup.enter()
            let db = Firestore.firestore()
            let friendRef = db.collection("userProfiles").document(friendID)
            friendRef.getDocument { friendSnapshot, error in
                defer { dispatchGroup.leave() }
                if let error = error {
                    print("Error fetching friend document: \(error.localizedDescription)")
                    return
                }
                guard let friendData = friendSnapshot?.data(),
                      let friendLikedItems = friendData["likedShows"] as? [Int] else {
                    print("Friend data not found or liked items not available.")
                    return
                }
                
                for showID in friendLikedItems {
                    if likedItems.contains(showID) {
                        if matchedShowIDs[showID] == nil {
                            matchedShowIDs[showID] = [String]()
                        }
                        matchedShowIDs[showID]?.append(friendID)
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if matchedShowIDs.isEmpty {
                completion()
                return
            }
            let uniqueShowIDs = Set(matchedShowIDs.keys)
            let totalShows = uniqueShowIDs.count
            var processedShows = 0

            for (showID, matchedFriendIDs) in matchedShowIDs {
                if matchedFriendIDs.contains(userId) {
                    fetchShowDetail(for: showID, matchedFriendIDs: matchedFriendIDs) {
                        processedShows += 1
                        if processedShows == totalShows {
                            completion()
                        }
                    }
                } else {
                    processedShows += 1
                    if processedShows == totalShows {
                        completion()
                    }
                }
            }
        }
    }

    private func fetchShowDetail(for showID: Int, matchedFriendIDs: [String], completion: @escaping () -> Void) {
        let apiKey = "" // tmdb api key goes here
        let urlString = "https://api.themoviedb.org/3/tv/\(showID)?api_key=\(apiKey)&language=en-US"
        guard let url = URL(string: urlString) else {
                    print("Invalid URL")
                    completion()
                    return
                }
                
                URLSession.shared.dataTask(with: url) { data, response, error in
                    if let data = data {
                        do {
                            let decoder = JSONDecoder()
                            var showDetail = try decoder.decode(ShowDetails.self, from: data)
                            
                            
                            let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                            if let posterPath = jsonResponse?["poster_path"] as? String {
                                showDetail.posterPath = posterPath
                            }
                            if let firstAirDate = jsonResponse?["first_air_date"] as? String {
                                                showDetail.firstAirDate = firstAirDate
                                            }
                            if let voteAverage = jsonResponse?["vote_average"] as? Double {
                                showDetail.voteAverage = voteAverage
                            }
                            if let ageRating = jsonResponse?["certification"] as? String {
                                showDetail.ageRating = ageRating
                            }
                            
                            
                            let dispatchGroup = DispatchGroup()
                            for friendID in matchedFriendIDs {
                                dispatchGroup.enter()
                                fetchUsername(for: friendID) { username in
                                    showDetail.matchedFriendUsername = username
                                    DispatchQueue.main.async {
                                        if !self.matchedShows.contains(where: { $0.id == showDetail.id }) {
                                            self.matchedShows.append(showDetail)
                                        }
                                        dispatchGroup.leave()
                                    }
                                }
                            }
                            dispatchGroup.notify(queue: .main) {
                                completion()
                            }
                        } catch {
                            print("Error decoding JSON: \(error)")
                            completion()
                        }
                    } else {
                        print("No data received")
                        completion()
                    }
                }.resume()
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

        struct ShowDetailView: View {
            let show: ShowDetails
            
            
            var body: some View {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.gradientTop, Color.gradientBottom]),
                                             startPoint: .top,
                                             endPoint: .bottom))
                    VStack {
                        if let posterPath = show.posterPath {
                            if let url = URL(string: "https://image.tmdb.org/t/p/original\(posterPath)") {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 300, height: 300)
                                    case .failure(let error):
                                        Text("Error loading image: \(error.localizedDescription)")
                                            .foregroundColor(.red)
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 300, height: 300)
                                    @unknown default:
                                        Color.gray
                                            .frame(width: 300, height: 300)
                                    }
                                }
                            } else {
                                Text("Invalid image URL")
                                    .foregroundColor(.red)
                            }
                        } else {
                            Text("No poster available")
                                .foregroundColor(.red)
                        }
                        
                        Text(show.name)
                            .font(.title)
                            .padding(.top)
                            .foregroundColor(.white)
                        
                        HStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 30)
                                .overlay(
                                    Text("Score: \(show.voteAverage ?? 0.0, specifier: "%.1f")")
                                        .foregroundColor(.white)
                                        .font(.subheadline)
                                )

                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 30)
                                .overlay(
                                    Text("\(show.firstAirDate ?? "Release Date Not Found")")
                                        .foregroundColor(.white)
                                        .font(.subheadline)
                                )
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 30)
                                .overlay(
                                    Text(" \(show.ageRating ?? "Age Rating Not Found")")
                                        .foregroundColor(.white)
                                        .font(.subheadline)
                                )
                        }
                        .padding(.top)
                        
                        Text(show.overview)
                            .foregroundColor(.white)
                            .font(.body)
                            .padding()
                            .lineLimit(nil)
                        

                    }
                    .padding()
                }
                .frame(maxWidth: 400, maxHeight: 800)
            }
        }
