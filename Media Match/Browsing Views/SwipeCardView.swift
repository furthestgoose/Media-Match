import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CardData: Identifiable, Equatable {
    var id = UUID()
    let movieID: Int
    let title: String
    let description: String
    let posterPath: String?
    
    static func == (lhs: CardData, rhs: CardData) -> Bool {
        lhs.id == rhs.id
    }
}

struct SwipeCardView: View {
    @State private var currentCards: [CardData] = []
    @State private var prefetchedPages: [[CardData]] = []
    @State private var offset = CGSize.zero
    @State private var rotation = 0.0
    @State private var currentPage = 1
    @State private var dislikedMovieIDs: Set<Int> = []
    @State private var showIntroduction = !UserDefaults.standard.bool(forKey: "hasSeenIntroduction")
    private let prefetchCount = 3
    private let userProfilesCollection = "userProfiles"
    
    var body: some View {
        ZStack {
            VStack {
                ZStack {
                    ForEach(currentCards) { card in
                        CardView(card: card, onLike: { offset = CGSize(width: 500, height: 0); handleSwipeRight(for: card); removeCard() },
                                 onDislike: { offset = CGSize(width: -500, height: 0); handleSwipeLeft(for: card); removeCard() })
                            .offset(x: card.id == currentCards.last?.id ? offset.width : 0, y: 0)
                            .rotationEffect(.degrees(card.id == currentCards.last?.id ? rotation : 0))
                            .scaleEffect(card.id == currentCards.last?.id ? 1 : 0.95)
                            .animation(.spring(), value: offset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        withAnimation(.linear(duration: 0.2)) {
                                            offset = value.translation
                                            rotation = Double(value.translation.width / 10)
                                        }
                                    }
                                    .onEnded { value in
                                        withAnimation(.spring()) {
                                            if value.translation.width > 100 {
                                                // Swipe right
                                                offset = CGSize(width: 500, height: 0)
                                                handleSwipeRight(for: card)
                                                removeCard()
                                            } else if value.translation.width < -100 {
                                                // Swipe left
                                                offset = CGSize(width: -500, height: 0)
                                                handleSwipeLeft(for: card)
                                                removeCard()
                                            } else {
                                                // Reset card position
                                                offset = .zero
                                                rotation = 0
                                            }
                                        }
                                    }
                            )
                    }
                }
                .padding()
                .onAppear {
                    fetchInitialMovies()
                }
            }
            
            if showIntroduction {
                IntroductionView(onDismiss: {
                    showIntroduction = false
                    UserDefaults.standard.set(true, forKey: "hasSeenIntroduction")
                })
            }
        }
    }
    
    private func removeCard() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            currentCards.removeLast()
            offset = .zero
            rotation = 0
            
            if currentCards.isEmpty {
                if !prefetchedPages.isEmpty {
                    withAnimation(.spring()) {
                        currentCards = prefetchedPages.removeFirst()
                    }
                }
                currentPage += 1
                fetchMovies(forPage: currentPage, excluding: dislikedMovieIDs)
            }
        }
    }
    
    private func fetchInitialMovies() {
        for page in currentPage...(currentPage + prefetchCount - 1) {
            fetchMovies(forPage: page, excluding: dislikedMovieIDs)
        }
        currentPage += prefetchCount
    }
    
    private func fetchMovies(forPage page: Int, excluding dislikedMovieIDs: Set<Int>) {
        guard let currentUser = Auth.auth().currentUser else {
            print("No user signed in")
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection(userProfilesCollection).document(currentUser.uid)
        
        userRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user document: \(error)")
                return
            }
            
            guard let userData = snapshot?.data() else {
                print("User data not found")
                return
            }
            
            let likedMovieIDs = userData["likedItems"] as? [Int] ?? []
            let dislikedMovieIDs = userData["dislikedItems"] as? [Int] ?? []
            
            let likedMovieIDSet = Set(likedMovieIDs)
            let dislikedMovieIDSet = Set(dislikedMovieIDs)
            
            let apiKey = "de362a6ab2bf7b2d1d8198a9d2d624d2"
            let urlString = "https://api.themoviedb.org/3/discover/movie"
            let parameters: [String: Any] = [
                "api_key": apiKey,
                "language": "en-US",
                "sort_by": "popularity.desc",
                "page": page
            ]
            
            guard let url = URL(string: urlString),
                  var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                print("Invalid URL")
                return
            }
            components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
            
            guard let finalURL = components.url else {
                print("Failed to construct URL")
                return
            }
            
            URLSession.shared.dataTask(with: finalURL) { data, response, error in
                if let data = data {
                    do {
                        let movieResponse = try JSONDecoder().decode(MovieResponse.self, from: data)
                        let movieIDs = movieResponse.results
                            .filter { !dislikedMovieIDSet.contains($0.id) && !likedMovieIDSet.contains($0.id) }
                            .map { $0.id }
                        
                        fetchMovieDetails(movieIDs: movieIDs) { movies in
                            let newCards = movies.map { movie in
                                CardData(movieID: movie.id, title: movie.title, description: movie.overview, posterPath: movie.posterPath)
                            }
                            DispatchQueue.main.async {
                                if self.currentCards.isEmpty {
                                    self.currentCards.append(contentsOf: newCards)
                                } else {
                                    self.prefetchedPages.append(newCards)
                                }
                            }
                        }
                    } catch {
                        print("Error decoding JSON: \(error)")
                    }
                } else {
                    print("No data received")
                }
            }.resume()
        }
    }
    
    private func fetchMovieDetails(movieIDs: [Int], completion: @escaping ([Movie]) -> Void) {
        let apiKey = "APIkey"
        let baseURL = "https://api.themoviedb.org/3/movie/"
        let parameters: [String: Any] = [
            "api_key": apiKey,
            "language": "en-US"
        ]
        
        var movies: [Movie] = []
        let group = DispatchGroup()
        
        for movieID in movieIDs {
            group.enter()
            
            let urlString = "\(baseURL)\(movieID)"
            guard let url = URL(string: urlString),
                  var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                group.leave()
                continue
            }
            components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
            
            guard let finalURL = components.url else {
                group.leave()
                continue
            }
            
            URLSession.shared.dataTask(with: finalURL) { data, response, error in
                defer {
                    group.leave()
                }
                
                if let data = data {
                    do {
                        let movie = try JSONDecoder().decode(Movie.self, from: data)
                        movies.append(movie)
                    } catch {
                        print("Error decoding JSON: \(error)")
                    }
                } else {
                    print("No data received")
                }
            }.resume()
        }
        
        group.notify(queue: .main) {
            completion(movies)
        }
    }
    
    func handleSwipeRight(for card: CardData) {
        addLikedItem(movieID: card.movieID)
    }
    
    func handleSwipeLeft(for card: CardData) {
        addDislikedItem(movieID: card.movieID)
        dislikedMovieIDs.insert(card.movieID)
    }
    
    private func addLikedItem(movieID: Int) {
        guard let currentUser = Auth.auth().currentUser else {
            print("No user signed in")
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection(userProfilesCollection).document(currentUser.uid)
        
        userRef.updateData(["likedItems": FieldValue.arrayUnion([movieID])]) { error in
            if let error = error {
                print("Error adding liked item to Firestore: \(error)")
            } else {
                print("Added liked item to Firestore")
            }
        }
    }

    
    private func addDislikedItem(movieID: Int) {
        guard let currentUser = Auth.auth().currentUser else {
            print("No user signed in")
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection(userProfilesCollection).document(currentUser.uid)
        
        userRef.updateData(["dislikedItems": FieldValue.arrayUnion([movieID])]) { error in
            if let error = error {
                print("Error adding disliked item to Firestore: \(error)")
            } else {
                print("Added disliked item to Firestore")
            }
        }
    }
}

struct CardView: View {
    let card: CardData
    let onLike: () -> Void
    let onDislike: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(gradient: Gradient(colors: [Color.gradientTop, Color.gradientBottom]),
                                     startPoint: .top,
                                     endPoint: .bottom))
            VStack {
                if let posterPath = card.posterPath {
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
                
                Text(card.title)
                    .font(.title)
                    .padding(.top)
                    .foregroundColor(.white)
                
                Text(card.description)
                    .foregroundColor(.white)
                    .font(.body)
                    .padding()
                    .lineLimit(nil)
                
                HStack{
                    Button(action: {
                            onDislike()
                        }) {
                            Image(systemName: "x.circle")
                                .font(.system(size: 40))
                        }
                        .foregroundColor(.red)
                    Spacer()
                        
                        Button(action: {
                            onLike()
                        }) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 40))
                        }
                        .foregroundColor(.green)
                    }
            }
            .padding()
        }
        .frame(width: 400, height: 700)
    }
}
// TMDB response structs

struct MovieResponse: Codable {
    let results: [Movie]
}

struct Movie: Codable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case posterPath = "poster_path"
    }
}
