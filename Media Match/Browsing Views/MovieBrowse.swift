import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CardData: Identifiable, Equatable, Hashable {
    var id = UUID()
    let movieID: Int
    let title: String
    let description: String
    let posterPath: String?
    let score: Double
    let releaseYear: String
    let ageRating: String
    
    static func == (lhs: CardData, rhs: CardData) -> Bool {
        lhs.id == rhs.id
    }
}

struct MovieBrowse: View {
    @State private var currentCards: [CardData] = []
    @State private var prefetchedPages: [[CardData]] = []
    @State private var offset = CGSize.zero
    @State private var rotation = 0.0
    @State private var currentPage = 1
    @State private var dislikedMovieIDs: Set<Int> = []
    @State private var showIntroduction = !UserDefaults.standard.bool(forKey: "hasSeenIntroduction")
    @State private var fetchedMovies: [CardData] = []
    @State private var selection = "All"
    @State private var providerSelection = "All"
    @State private var regionSelection = "All"
    @State private var filterby = "28"
    @State private var regioncode = "US"
    let choice = ["All","Action", "Adventure", "Animation", "Comedy", "Crime", "Documentary","Drama", "Family", "Fantasy", "Horror", "History", "Music", "Mystery", "Romance", "Science Fiction", "TV Movie", "Thriller", "War", "Western"]
    let provider = ["All", "Netflix", "Apple TV", "Amazon Prime Video","Disney Plus", "HBO Max" ]
    let region = [
        "All",
        "Andorra",
        "United Arab Emirates",
        "Antigua and Barbuda",
        "Albania",
        "Angola",
        "Argentina",
        "Austria",
        "Australia",
        "Azerbaijan",
        "Bosnia and Herzegovina",
        "Barbados",
        "Belgium",
        "Burkina Faso",
        "Bulgaria",
        "Bahrain",
        "Bermuda",
        "Bolivia",
        "Brazil",
        "Bahamas",
        "Belarus",
        "Belize",
        "Canada",
        "Congo",
        "Switzerland",
        "Cote D'Ivoire",
        "Chile",
        "Cameroon",
        "Colombia",
        "Costa Rica",
        "Cuba",
        "Cape Verde",
        "Cyprus",
        "Czech Republic",
        "Germany",
        "Denmark",
        "Dominican Republic",
        "Algeria",
        "Ecuador",
        "Estonia",
        "Egypt",
        "Spain",
        "Finland",
        "Fiji",
        "France",
        "United Kingdom",
        "French Guiana",
        "Ghana",
        "Gibraltar",
        "Guadaloupe",
        "Equatorial Guinea",
        "Greece",
        "Guatemala",
        "Guyana",
        "Hong Kong",
        "Honduras",
        "Croatia",
        "Hungary",
        "Indonesia",
        "Ireland",
        "Israel",
        "India",
        "Iraq",
        "Iceland",
        "Italy",
        "Jamaica",
        "Jordan",
        "Japan",
        "Kenya",
        "South Korea",
        "Kuwait",
        "Lebanon",
        "St. Lucia",
        "Liechtenstein",
        "Lithuania",
        "Luxembourg",
        "Latvia",
        "Libyan Arab Jamahiriya",
        "Morocco",
        "Monaco",
        "Moldova",
        "Montenegro",
        "Madagascar",
        "Macedonia",
        "Mali",
        "Malta",
        "Mauritius",
        "Malawi",
        "Mexico",
        "Malaysia",
        "Mozambique",
        "Niger",
        "Nigeria",
        "Nicaragua",
        "Netherlands",
        "Norway",
        "New Zealand",
        "Oman",
        "Panama",
        "Peru",
        "French Polynesia",
        "Papua New Guinea",
        "Philippines",
        "Pakistan",
        "Poland",
        "Palestinian Territory",
        "Portugal",
        "Paraguay",
        "Qatar",
        "Romania",
        "Serbia",
        "Russia",
        "Saudi Arabia",
        "Seychelles",
        "Sweden",
        "Singapore",
        "Slovenia",
        "Slovakia",
        "San Marino",
        "Senegal",
        "El Salvador",
        "Turks and Caicos Islands",
        "Chad",
        "Thailand",
        "Tunisia",
        "Turkey",
        "Trinidad and Tobago",
        "Taiwan",
        "Tanzania",
        "Ukraine",
        "Uganda",
        "United States of America",
        "Uruguay",
        "Holy See",
        "Venezuela",
        "Kosovo",
        "Yemen",
        "South Africa",
        "Zambia",
        "Zimbabwe"
    ]
    private let prefetchCount = 3
    private let userProfilesCollection = "userProfiles"
    
    var body: some View {
        GeometryReader { geometry in
            let isIPad = geometry.size.width >= 748
            let scale = isIPad ? 1.5 : 1.0
        NavigationStack {
            ZStack {
                VStack {
                    ZStack {
                        ForEach(currentCards) { card in
                            MovieCardView(card: card, onLike: { offset = CGSize(width: 500, height: 0); handleSwipeRight(for: card); removeCard() },
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
                    .frame(
                                            width: isIPad ? geometry.size.width * 0.8 : geometry.size.width,
                                            height: isIPad ? geometry.size.height * 0.8 : geometry.size.height,
                                            alignment: .center
                                        )
                                        .scaleEffect(scale)
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
        .frame(width: geometry.size.width, height: geometry.size.height)
                    .background(Color.white)
                    .ignoresSafeArea()
            .toolbar {
                
                ToolbarItem(placement: .topBarTrailing){
                    Menu{
                        Picker("Select a Genre", selection: $selection) {
                            ForEach(choice, id: \.self) {
                                Text($0)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: selection) { newValue in
                            switch newValue {
                            case "Action":
                                filterby = "28"
                            case "Adventure":
                                filterby = "12"
                            case "Animation":
                                filterby = "16"
                            case "Comedy":
                                filterby = "35"
                            case "Crime":
                                filterby = "80"
                            case "Documentary":
                                filterby = "99"
                            case "Drama":
                                filterby = "18"
                            case "Family":
                                filterby = "10751"
                            case "Fantasy":
                                filterby = "14"
                            case "Horror":
                                filterby = "27"
                            case "History":
                                filterby = "36"
                            case "Music":
                                filterby = "10402"
                            case "Mystery":
                                filterby = "9648"
                            case "Romance":
                                filterby = "10749"
                            case "Science Fiction":
                                filterby = "878"
                            case "TV Movie":
                                filterby = "10770"
                            case "Thriller":
                                filterby = "53"
                            case "War":
                                filterby = "10752"
                            case "Western":
                                filterby = "37"
                            default:
                                filterby = ""
                            }
                            resetAndFetchMovies()
                        }
                        Picker("Select a Streaming Service", selection: $providerSelection) {
                            ForEach(provider, id: \.self) {
                                Text($0)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: providerSelection) { newValue in
                            resetAndFetchMovies()
                        }
                        Picker("Select a Region", selection: $regionSelection) {
                            ForEach(region, id: \.self) {
                                Text($0)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: regionSelection) { newValue in
                            switch newValue {
                            case "Andorra":
                                regioncode = "AD"
                            case "United Arab Emirates":
                                regioncode = "AE"
                            case "Antigua and Barbuda":
                                regioncode = "AG"
                            case "Albania":
                                regioncode = "AL"
                            case "Angola":
                                regioncode = "AO"
                            case "Argentina":
                                regioncode = "AR"
                            case "Austria":
                                regioncode = "AT"
                            case "Australia":
                                regioncode = "AU"
                            case "Azerbaijan":
                                regioncode = "AZ"
                            case "Bosnia and Herzegovina":
                                regioncode = "BA"
                            case "Barbados":
                                regioncode = "BB"
                            case "Belgium":
                                regioncode = "BE"
                            case "Burkina Faso":
                                regioncode = "BF"
                            case "Bulgaria":
                                regioncode = "BG"
                            case "Bahrain":
                                regioncode = "BH"
                            case "Bermuda":
                                regioncode = "BM"
                            case "Bolivia":
                                regioncode = "BO"
                            case "Brazil":
                                regioncode = "BR"
                            case "Bahamas":
                                regioncode = "BS"
                            case "Belarus":
                                regioncode = "BY"
                            case "Belize":
                                regioncode = "BZ"
                            case "Canada":
                                regioncode = "CA"
                            case "Congo":
                                regioncode = "CD"
                            case "Switzerland":
                                regioncode = "CH"
                            case "Cote D'Ivoire":
                                regioncode = "CI"
                            case "Chile":
                                regioncode = "CL"
                            case "Cameroon":
                                regioncode = "CM"
                            case "Colombia":
                                regioncode = "CO"
                            case "Costa Rica":
                                regioncode = "CR"
                            case "Cuba":
                                regioncode = "CU"
                            case "Cape Verde":
                                regioncode = "CV"
                            case "Cyprus":
                                regioncode = "CY"
                            case "Czech Republic":
                                regioncode = "CZ"
                            case "Germany":
                                regioncode = "DE"
                            case "Denmark":
                                regioncode = "DK"
                            case "Dominican Republic":
                                regioncode = "DO"
                            case "Algeria":
                                regioncode = "DZ"
                            case "Ecuador":
                                regioncode = "EC"
                            case "Estonia":
                                regioncode = "EE"
                            case "Egypt":
                                regioncode = "EG"
                            case "Spain":
                                regioncode = "ES"
                            case "Finland":
                                regioncode = "FI"
                            case "Fiji":
                                regioncode = "FJ"
                            case "France":
                                regioncode = "FR"
                            case "United Kingdom":
                                regioncode = "GB"
                            case "French Guiana":
                                regioncode = "GF"
                            case "Ghana":
                                regioncode = "GH"
                            case "Gibraltar":
                                regioncode = "GI"
                            case "Guadaloupe":
                                regioncode = "GP"
                            case "Equatorial Guinea":
                                regioncode = "GQ"
                            case "Greece":
                                regioncode = "GR"
                            case "Guatemala":
                                regioncode = "GT"
                            case "Guyana":
                                regioncode = "GY"
                            case "Hong Kong":
                                regioncode = "HK"
                            case "Honduras":
                                regioncode = "HN"
                            case "Croatia":
                                regioncode = "HR"
                            case "Hungary":
                                regioncode = "HU"
                            case "Indonesia":
                                regioncode = "ID"
                            case "Ireland":
                                regioncode = "IE"
                            case "Israel":
                                regioncode = "IL"
                            case "India":
                                regioncode = "IN"
                            case "Iraq":
                                regioncode = "IQ"
                            case "Iceland":
                                regioncode = "IS"
                            case "Italy":
                                regioncode = "IT"
                            case "Jamaica":
                                regioncode = "JM"
                            case "Jordan":
                                regioncode = "JO"
                            case "Japan":
                                regioncode = "JP"
                            case "Kenya":
                                regioncode = "KE"
                            case "South Korea":
                                regioncode = "KR"
                            case "Kuwait":
                                regioncode = "KW"
                            case "Lebanon":
                                regioncode = "LB"
                            case "St. Lucia":
                                regioncode = "LC"
                            case "Liechtenstein":
                                regioncode = "LI"
                            case "Lithuania":
                                regioncode = "LT"
                            case "Luxembourg":
                                regioncode = "LU"
                            case "Latvia":
                                regioncode = "LV"
                            case "Libyan Arab Jamahiriya":
                                regioncode = "LY"
                            case "Morocco":
                                regioncode = "MA"
                            case "Monaco":
                                regioncode = "MC"
                            case "Moldova":
                                regioncode = "MD"
                            case "Montenegro":
                                regioncode = "ME"
                            case "Madagascar":
                                regioncode = "MG"
                            case "Macedonia":
                                regioncode = "MK"
                            case "Mali":
                                regioncode = "ML"
                            case "Malta":
                                regioncode = "MT"
                            case "Mauritius":
                                regioncode = "MU"
                            case "Malawi":
                                regioncode = "MW"
                            case "Mexico":
                                regioncode = "MX"
                            case "Malaysia":
                                regioncode = "MY"
                            case "Mozambique":
                                regioncode = "MZ"
                            case "Niger":
                                regioncode = "NE"
                            case "Nigeria":
                                regioncode = "NG"
                            case "Nicaragua":
                                regioncode = "NI"
                            case "Netherlands":
                                regioncode = "NL"
                            case "Norway":
                                regioncode = "NO"
                            case "New Zealand":
                                regioncode = "NZ"
                            case "Oman":
                                regioncode = "OM"
                            case "Panama":
                                regioncode = "PA"
                            case "French Polynesia":
                                regioncode = "PF"
                            case "Papua New Guinea":
                                regioncode = "PG"
                            case "Philippines":
                                regioncode = "PH"
                            case "Pakistan":
                                regioncode = "PK"
                            case "Poland":
                                regioncode = "PL"
                            case "Palestinian Territory":
                                regioncode = "PS"
                            case "Portugal":
                                regioncode = "PT"
                            case "Paraguay":
                                regioncode = "PY"
                            case "Qatar":
                                regioncode = "QA"
                            case "Romania":
                                regioncode = "RO"
                            case "Serbia":
                                regioncode = "RS"
                            case "Russia":
                                regioncode = "RU"
                            case "Saudi Arabia":
                                regioncode = "SA"
                            case "Seychelles":
                                regioncode = "SC"
                            case "Sweden":
                                regioncode = "SE"
                            case "Singapore":
                                regioncode = "SG"
                            case "Slovenia":
                                regioncode = "SI"
                            case "Slovakia":
                                regioncode = "SK"
                            case "San Marino":
                                regioncode = "SM"
                            case "Senegal":
                                regioncode = "SN"
                            case "El Salvador":
                                regioncode = "SV"
                            case "Turks and Caicos Islands":
                                regioncode = "TC"
                            case "Chad":
                                regioncode = "TD"
                            case "Thailand":
                                regioncode = "TH"
                            case "Tunisia":
                                regioncode = "TN"
                            case "Turkey":
                                regioncode = "TR"
                            case "Trinidad and Tobago":
                                regioncode = "TT"
                            case "Taiwan":
                                regioncode = "TW"
                            case "Tanzania":
                                regioncode = "TZ"
                            case "Ukraine":
                                regioncode = "UA"
                            case "Uganda":
                                regioncode = "UG"
                            case "United States of America":
                                regioncode = "US"
                            case "Uruguay":
                                regioncode = "UY"
                            case "Holy See":
                                regioncode = "VA"
                            case "Venezuela":
                                regioncode = "VE"
                            case "Kosovo":
                                regioncode = "XK"
                            case "Yemen":
                                regioncode = "YE"
                            case "South Africa":
                                regioncode = "ZA"
                            case "Zambia":
                                regioncode = "ZM"
                            case "Zimbabwe":
                                regioncode = "ZW"
                            default:
                                regioncode = ""
                            }
                            resetAndFetchMovies()
                        }
                    }label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.blue)
                    }
                }
            }
            .toolbar(.hidden, for: .tabBar)
        }
    }
    
    private func resetAndFetchMovies() {
            currentCards = []
            prefetchedPages = []
            currentPage = 1
            fetchInitialMovies()
        }
    
    private func removeCard() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            currentCards.removeLast()
            offset = .zero
            rotation = 0

            if currentCards.isEmpty && !self.fetchedMovies.isEmpty {
                withAnimation(.spring()) {
                    currentCards = self.fetchedMovies
                    self.fetchedMovies.removeAll()
                }
            }

            if currentCards.isEmpty {
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

            let apiKey = "009613fd608f174b8bde1c5e00e56640"
            let urlString = "https://api.themoviedb.org/3/discover/movie"

            var parameters: [String: Any] = [
                "api_key": apiKey,
                "language": "en-US",
                "sort_by": "popularity.desc",
                "page": page
            ]

            if !filterby.isEmpty {
                parameters["with_genres"] = filterby
            }

            if providerSelection != "All" {
                parameters["with_watch_providers"] = providerSelection
            }

            if !regioncode.isEmpty {
                parameters["watch_regions"] = regioncode
            }

            var components = URLComponents(string: urlString)!
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

                        self.fetchMovieDetails(movieIDs: movieIDs) { movies in
                            let newCards = movies.map { movie in
                                CardData(
                                    movieID: movie.id,
                                    title: movie.title,
                                    description: movie.overview,
                                    posterPath: movie.posterPath,
                                    score: movie.voteAverage,
                                    releaseYear: movie.releaseDate,
                                    ageRating: movie.ageRating ?? "Rating Not Found"
                                )
                            }
                            DispatchQueue.main.async {
                                let uniqueCards = Array(Set(newCards + self.currentCards))
                                self.currentCards = uniqueCards
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
        let apiKey = "009613fd608f174b8bde1c5e00e56640"
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
                        
                        let releaseDatesURL = URL(string: "\(baseURL)\(movieID)/release_dates?api_key=\(apiKey)")!
                        URLSession.shared.dataTask(with: releaseDatesURL) { releaseDatesData, releaseDatesResponse, releaseDatesError in
                            if let releaseDatesData = releaseDatesData {
                                do {
                                    let releaseDatesResponse = try JSONDecoder().decode(ReleaseDatesResponse.self, from: releaseDatesData)
                                    
                                    // Find the age rating for the US region
                                    if let usReleaseDate = releaseDatesResponse.results.first(where: { $0.iso31661 == "GB" }),
                                       let usRelease = usReleaseDate.releaseDates.first(where: { $0.certification != nil }),
                                       let certification = usRelease.certification {
                                        var updatedMovie = movie
                                        updatedMovie.ageRating = certification
                                        movies.append(updatedMovie)
                                    } else {
                                        movies.append(movie)
                                    }
                                } catch {
                                    print("Error decoding release dates JSON: \(error)")
                                    movies.append(movie)        }
                            } else {
                                print("No release dates data received")
                                movies.append(movie)
                            }
                            
                            if movies.count == movieIDs.count {
                                completion(movies)
                            }
                        }.resume()
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
        
        userRef.updateData(["likedMovies": FieldValue.arrayUnion([movieID])]) { error in
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
        
        userRef.updateData(["dislikedMovies": FieldValue.arrayUnion([movieID])]) { error in
            if let error = error {
                print("Error adding disliked item to Firestore: \(error)")
            } else {
                print("Added disliked item to Firestore")
            }
        }
    }
}

struct MovieCardView: View {
    let card: CardData
    let onLike: () -> Void
    let onDislike: () -> Void

    @State private var isExpanded = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(gradient: Gradient(colors: [Color.gradientTop, Color.gradientBottom]),
                                     startPoint: .top,
                                     endPoint: .bottom))
            ScrollView {
                VStack() {
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

                    HStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 30)
                            .overlay(
                                Text("Score: \(card.score, specifier: "%.1f")")
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                            )

                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 30)
                            .overlay(
                                Text("\(card.releaseYear)")
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                            )

                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 30)
                            .overlay(
                                Text(" \(card.ageRating)")
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                            )
                    }
                    .padding(.top)

                    Text(card.description)
                        .foregroundColor(.white)
                        .font(.body)
                        .padding()
                        .lineLimit(isExpanded ? nil : 5)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                isExpanded.toggle()
                            }
                        }

                    HStack {
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
                    .padding()
                }
                .padding()
            }
        }
        .frame(maxWidth: 400, maxHeight: 700)
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
    let voteAverage: Double
    let releaseDate: String
    var ageRating: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case posterPath = "poster_path"
        case voteAverage = "vote_average"
        case releaseDate = "release_date"
        case ageRating = "certification"
    }
}

struct ReleaseDatesResponse: Codable {
    let results: [ReleaseDatesResult]
}

struct ReleaseDatesResult: Codable {
    let iso31661: String
    let releaseDates: [ReleaseDate]
    
    enum CodingKeys: String, CodingKey {
        case iso31661 = "iso_3166_1"
        case releaseDates = "release_dates"
    }
}

struct ReleaseDate: Codable {
    let certification: String?
    let iso6391: String?
    let note: String?
    let releaseDate: String?
    let type: Int?
    
    enum CodingKeys: String, CodingKey {
        case certification
        case iso6391 = "iso_639_1"
        case note
        case releaseDate = "release_date"
        case type
    }
}
 
