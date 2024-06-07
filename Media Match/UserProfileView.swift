import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SDWebImage

struct UserProfileView: View {
    @EnvironmentObject var authService: AuthService
    @State private var userProfile: UserProfile?
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isUploading = false
    @State private var showDeleteAccountAlert = false // New state variable
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue
    var body: some View {
            ZStack {
                VStack {
                    if let profile = userProfile {
                        Form {
                            Section(header: Text("Profile")) {
                                HStack {
                                    Spacer()
                                    if let imageUrl = profile.profilePictureURL, let url = URL(string: imageUrl), !imageUrl.isEmpty {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 100, height: 100)
                                                    .clipShape(Circle())
                                            case .failure(_):
                                                Image("default-profile")
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 100, height: 100)
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
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                    }
                                    Spacer()
                                }
                                
                                HStack {
                                    Spacer()
                                    Text(profile.username.prefix(1).capitalized + profile.username.dropFirst())
                                        .font(.subheadline)
                                    Spacer()
                                }
                            }
                            
                            Section (header: Text("Account actions")){
                                Button(action: {
                                    showImagePicker = true
                                }) {
                                    Label("Upload Profile Picture", systemImage: "icloud.and.arrow.up")
                                }
                                .buttonStyle(.plain)
                                .sheet(isPresented: $showImagePicker) {
                                    ImagePicker(image: $selectedImage)
                                        .onDisappear {
                                            if let selectedImage = selectedImage {
                                                uploadProfilePicture(image: selectedImage)
                                            }
                                        }
                                }
                                
                                NavigationLink(destination: passwordResetView()) {
                                    Label("Reset your password", systemImage: "lock.open.rotation")
                                }
                                .buttonStyle(.plain)
                                HStack{
                                    Text("Theme:")
                                    Picker("Appearance", selection: $appearanceMode) {
                                        ForEach(AppearanceMode.allCases) { mode in
                                            Text(mode.rawValue).tag(mode.rawValue)
                                        }
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                }
                            }
                            
                            Section (header: Label("Danger Zone", systemImage: "exclamationmark.triangle") .foregroundColor(.red)){
                                Button(action: {
                                    logOut()
                                }) {
                                    Label("Log out", systemImage: "rectangle.portrait.and.arrow.forward")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                                .cornerRadius(10)
                                
                                Button(action: {
                                    showDeleteAccountAlert = true // Show the alert when clicked
                                }) {
                                    Label("Delete Account", systemImage: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                                .alert(isPresented: $showDeleteAccountAlert) {
                                    Alert(
                                        title: Text("Delete Account"),
                                        message: Text("Are you sure you want to delete your account? This action is irreversible."),
                                        primaryButton: .destructive(Text("Delete")) {
                                            authService.deleteAccount()
                                            logOut()
                                        },
                                        secondaryButton: .cancel()
                                    )
                                }
                                
                                Text("Warning: Deleting your account is irreversible. All your data will be permanently removed.")
                                    .foregroundColor(.red)
                                    .font(.footnote)
                            }
                        }
                    } else {
                        ProgressView()
                    }
                }
                .onAppear {
                    fetchUserProfile()
                }
                .alert(isPresented: $isUploading) {
                    Alert(title: Text("Uploading"), message: Text("Uploading profile picture..."))
                }
                .toolbar(.hidden, for: .tabBar)
        }
    }
    
    private func logOut() {
        print("Log out tapped!")
        authService.regularSignOut { error in
            if let e = error {
                print(e.localizedDescription)
            }
        }
        
        authService.googleSignOut()
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
    
    private func uploadProfilePicture(image: UIImage) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let storageRef = Storage.storage().reference().child("profile_pictures/\(userId).jpg")
        
        guard let imageData = image.jpegData(compressionQuality: 0.0) else { return } // Compress image
        
        isUploading = true
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading profile picture: \(error.localizedDescription)")
                isUploading = false
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    isUploading = false
                    return
                }
                
                guard let downloadURL = url else {
                    isUploading = false
                    return
                }
                
                let db = Firestore.firestore()
                db.collection("userProfiles").document(userId).updateData([
                    "profilePictureURL": downloadURL.absoluteString
                ]) { error in
                    isUploading = false
                    if let error = error {
                        print("Error updating profile picture URL: \(error.localizedDescription)")
                        return
                    }
                    fetchUserProfile() // Refresh user profile
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

#Preview {
    UserProfileView()
}

