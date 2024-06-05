import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MovieDetails: Codable {
    let id: Int
    let title: String
    let overview: String
    var posterPath: String?
    var matchedFriendUsername: String?
}

struct MatchView: View {
    @State private var userID: String? // User's ID
    @State private var friendIDs: [String]? // IDs of the user's friends
    
    @State private var matchedMovies: [MovieDetails] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            Text("Matches")
                .font(.title)
                .padding()
            
            if isLoading {
                ProgressView()
                    .padding()
            } else if matchedMovies.isEmpty {
                Text("No matches found")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(matchedMovies, id: \.id) { movie in
                            MovieDetailView(movie: movie)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            fetchUserData()
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
            
            // Find matched movies
            if let likedItems = userData["likedItems"] as? [Int], let friendIDs = self.friendIDs {
                findMatchedMovies(userID: userID, likedItems: likedItems, friendIDs: friendIDs) {
                    self.isLoading = false
                }
            } else {
                self.isLoading = false
            }
        }
    }
    
    private func findMatchedMovies(userID: String, likedItems: [Int], friendIDs: [String], completion: @escaping () -> Void) {
        var matchedMovieIDs: [Int: String] = [:] // Dictionary to store matched movie IDs and matched friend IDs
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
                      let friendLikedItems = friendData["likedItems"] as? [Int] else {
                    print("Friend data not found or liked items not available.")
                    return
                }
                // Compare liked movies of user and friend to find matches
                for movieID in friendLikedItems {
                    if likedItems.contains(movieID) {
                        matchedMovieIDs[movieID] = friendID
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if matchedMovieIDs.isEmpty {
                completion()
                return
            }
            for (movieID, friendID) in matchedMovieIDs {
                fetchMovieDetail(for: movieID, matchedFriendID: friendID) {
                    completion()
                }
            }
        }
    }
    private func fetchMovieDetail(for movieID: Int, matchedFriendID: String, completion: @escaping () -> Void) {
        let apiKey = "APIkey"
        let urlString = "https://api.themoviedb.org/3/movie/\(movieID)"
        let parameters: [String: Any] = [
            "api_key": apiKey,
            "language": "en-US"
        ]
        
        guard let url = URL(string: urlString),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            print("Invalid URL")
            completion()
            return
        }
        components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        
        guard let finalURL = components.url else {
            print("Failed to construct URL")
            completion()
            return
        }
        
        URLSession.shared.dataTask(with: finalURL) { data, response, error in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    // Decode the response into a dictionary
                    guard let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                        print("Failed to decode JSON")
                        completion()
                        return
                    }
                    
                    // Extract the poster path from the JSON dictionary
                    if let posterPath = jsonResponse["poster_path"] as? String {
                        var movieDetail = try decoder.decode(MovieDetails.self, from: data)
                        movieDetail.posterPath = posterPath
                        // Add matched friend's username to movie detail
                        fetchUsername(for: matchedFriendID) { username in
                            movieDetail.matchedFriendUsername = username
                            DispatchQueue.main.async {
                                self.matchedMovies.append(movieDetail)
                            }
                            completion()
                        }
                    } else {
                        print("Poster path not found in JSON response")
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

struct MovieDetailView: View {
    let movie: MovieDetails
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(gradient: Gradient(colors: [Color.gradientTop, Color.gradientBottom]),
                                     startPoint: .top,
                                     endPoint: .bottom))
            VStack {
                if let posterPath = movie.posterPath {
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
                
                Text(movie.title)
                    .font(.title)
                    .padding(.top)
                    .foregroundColor(.white)
                
                Text(movie.overview)
                    .foregroundColor(.white)
                    .font(.body)
                    .padding()
                    .lineLimit(nil)
                
                if let matchedFriendUsername = movie.matchedFriendUsername {
                    Text("Matched with: \(matchedFriendUsername)")
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.gray.opacity(0.2)) // Grey background
                        .cornerRadius(16)
                        .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.blue, lineWidth: 1)
                            )
                        .font(.subheadline)
                        .padding(.top)
                }
            }
            .padding()
        }
        .frame(maxWidth: 400, maxHeight: 800)
    }
    
    private func posterURL(for posterPath: String) -> URL? {
        let baseURL = "https://image.tmdb.org/t/p/w500"
        let posterURL = "\(baseURL)\(posterPath)"
        return URL(string: posterURL)
    }
}

