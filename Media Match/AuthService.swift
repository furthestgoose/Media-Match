import Foundation
import FirebaseCore
import FirebaseAuth
import CryptoKit
import AuthenticationServices
import GoogleSignIn
import FirebaseFirestore
import FirebaseStorage


class AuthService: ObservableObject {
    @Published var signedIn:Bool = false
    
    init() {
        Auth.auth().addStateDidChangeListener() { auth, user in
            if user != nil {
                self.signedIn = true
                print("Auth state changed, is signed in")
            } else {
                self.signedIn = false
                print("Auth state changed, is signed out")
            }
        }
    }
    
    // MARK: - Password Account
    func regularCreateAccount(email: String, password: String,username: String, completion: @escaping (Error?) -> Void) {
        let db = Firestore.firestore()
        let userRef = db.collection("userProfiles")
        
        
        guard isValidEmail(email) else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid email address."])
            completion(error)
            return
        }
        
        guard password.count >= 6 else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Password must be at least 6 characters long."])
            completion(error)
            return
        }
        
        let uppercaseLetterRegex = ".*[A-Z]+.*"
        let uppercaseLetterTest = NSPredicate(format: "SELF MATCHES %@", uppercaseLetterRegex)
        guard uppercaseLetterTest.evaluate(with: password) else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Password must contain at least one uppercase letter."])
            completion(error)
            return
        }
        
        let numberRegex = ".*[0-9]+.*"
        let numberTest = NSPredicate(format: "SELF MATCHES %@", numberRegex)
        guard numberTest.evaluate(with: password) else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Password must contain at least one number."])
            completion(error)
            return
        }
        
        let specialCharacterRegex = ".*[!@#$&*]+.*"
        let specialCharacterTest = NSPredicate(format: "SELF MATCHES %@", specialCharacterRegex)
        guard specialCharacterTest.evaluate(with: password) else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Password must contain at least one special character."])
            completion(error)
            return
        }
        
        userRef.whereField("username", isEqualTo: username).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error checking username: \(error.localizedDescription)")
                completion(error)
                return
            }
            
            if let querySnapshot = querySnapshot, !querySnapshot.isEmpty {
                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Username already in use."])
                completion(error)
                return
            }
            
            guard username.count >= 6 else{
                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Username must be at least 6 characters long"])
                completion(error)
                return
            }
            
            Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
                if let error = error as NSError? {
                    switch error.code {
                    case AuthErrorCode.emailAlreadyInUse.rawValue:
                        let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "email already in use."])
                        completion(error)
                        print("email in use")
                        return
                    default:
                        print("Error: \(error.localizedDescription)")
                    }
                    completion(error)
                    return
                }
                
                print("Sign in successful!")
                
                guard let userID = authResult?.user.uid else {
                    return
                }
                userRef.document(userID).setData([
                    "username": "\(username)",
                ]) { error in
                    if let error = error {
                        print("Error adding user data to Firestore: \(error.localizedDescription)")
                    } else {
                        print("User data added to Firestore successfully")
                    }
                }
            }
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
            let emailRegex = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
            let emailTest = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
            return emailTest.evaluate(with: email)
        }
    
    //MARK: - Traditional sign in
    func regularSignIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        
        guard isValidEmail(email) else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid email address."])
            completion(error)
            return
        }
        
        guard password.count >= 6 else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Password must be at least 6 characters long."])
            completion(error)
            return
        }
        
        let uppercaseLetterRegex = ".*[A-Z]+.*"
        let uppercaseLetterTest = NSPredicate(format: "SELF MATCHES %@", uppercaseLetterRegex)
        guard uppercaseLetterTest.evaluate(with: password) else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Password must contain at least one uppercase letter."])
            completion(error)
            return
        }
        
        let numberRegex = ".*[0-9]+.*"
        let numberTest = NSPredicate(format: "SELF MATCHES %@", numberRegex)
        guard numberTest.evaluate(with: password) else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Password must contain at least one number."])
            completion(error)
            return
        }
        
        let specialCharacterRegex = ".*[!@#$&*]+.*"
        let specialCharacterTest = NSPredicate(format: "SELF MATCHES %@", specialCharacterRegex)
        guard specialCharacterTest.evaluate(with: password) else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Password must contain at least one special character."])
            completion(error)
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                if let error = error as NSError? {
                    switch error.code {
                    case AuthErrorCode.userNotFound.rawValue:
                        let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "email not found"])
                        completion(error)
                        return
                    case AuthErrorCode.wrongPassword.rawValue:
                        let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Password is incorrect"])
                        completion(error)
                        return
                    default:
                        print("Error: \(error.localizedDescription)")
                    }
                    return
                }
                print("Sign in successful!")
            }
    }



    
    //MARK: Regular password acount sign out.
    func regularSignOut(completion: @escaping (Error?) -> Void) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            completion(nil)
        } catch let signOutError as NSError {
          print("Error signing out: %@", signOutError)
          completion(signOutError)
        }
    }
    //MARK: google sign in
    func googleSignIn() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        let config = GIDConfiguration(clientID: clientID)
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        guard let rootViewController = windowScene.windows.first?.rootViewController else { return }

        GIDSignIn.sharedInstance.signIn(with: config, presenting: rootViewController) { [unowned self] user, error in
            if let error = error {
                print("Error doing Google Sign-In, \(error)")
                return
            }

            guard
                let authentication = user?.authentication,
                let idToken = authentication.idToken,
                let email = user?.profile?.email
            else {
                print("Error during Google Sign-In authentication, \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken)

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }

                print("Signed in with Google")
                
                let emailPrefix = email.components(separatedBy: "@").first ?? ""
                self.checkAndSaveUsername(username: emailPrefix, email: email)
            }
        }
    }

    func checkAndSaveUsername(username: String, email: String) {
        let db = Firestore.firestore()
        let userRef = db.collection("userProfiles")

        userRef.whereField("username", isEqualTo: username).getDocuments { [unowned self] (querySnapshot, error) in
            if let error = error {
                print("Error checking username: \(error.localizedDescription)")
                return
            }

            if let querySnapshot = querySnapshot, !querySnapshot.isEmpty {
                let newUsername = username + "\(querySnapshot.count + 1)"
                self.saveUsernameToFirestore(username: newUsername, email: email)
            } else {
                self.saveUsernameToFirestore(username: username, email: email)
            }
        }
    }

    func saveUsernameToFirestore(username: String, email: String) {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        let userRef = Firestore.firestore().collection("userProfiles").document(userID)
        userRef.setData([
            "username": username,
            "email": email
        ]) { error in
            if let error = error {
                print("Error adding user data to Firestore: \(error.localizedDescription)")
            } else {
                print("User data added to Firestore successfully")
            }
        }
    }

    //MARK: google sign out
    func googleSignOut() {
        GIDSignIn.sharedInstance.signOut()
        print("Google sign out")
    }
    
    //MARK: password reset
    func passwordReset(email: String,completion: @escaping (Error?) -> Void){
        guard isValidEmail(email) else {
                    let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid email address."])
                    completion(error)
                    return
                }
        
        Auth.auth().sendPasswordReset(withEmail: email) { (error) in
                    if let error = error as NSError? {
                        switch error.code {
                        case AuthErrorCode.userNotFound.rawValue:
                            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "email not found"])
                            completion(error)
                            return
                        default:
                            print("Error: \(error.localizedDescription)")
                        }
                        return
                    }
                    print("Sign in successful!")
                    let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Password reset sent"])
                    completion(error)
                }
    }
    
    //MARK: account deletion
    func deleteAccount() {
        guard let user = Auth.auth().currentUser else {
            print("No user signed in")
            return
        }

        let db = Firestore.firestore()
        let userProfilesRef = db.collection("userProfiles")


        userProfilesRef.whereField("friends", arrayContains: user.uid).getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching user profiles: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else {
                print("No user profiles found")
                return
            }

            let dispatchGroup = DispatchGroup()

            for document in documents {
                let userId = document.documentID

                if userId == user.uid {
                    continue
                }

                dispatchGroup.enter()
                userProfilesRef.document(userId).updateData(["friends": FieldValue.arrayRemove([user.uid])]) { error in
                    dispatchGroup.leave()
                    if let error = error {
                        print("Error removing user from friends array: \(error.localizedDescription)")
                    } else {
                        print("User removed from friends array successfully")
                    }
                }
            }

            dispatchGroup.notify(queue: .main) {
                self.deleteRemainingData(for: user)
            }
        }
    }

    func deleteRemainingData(for user: User) {
        let db = Firestore.firestore()

        let friendRequestsRef = db.collection("friendRequests").document(user.uid)
        friendRequestsRef.delete { error in
            if let error = error {
                print("Error deleting friendRequests document: \(error.localizedDescription)")
            } else {
                print("friendRequests document successfully deleted!")
            }
        }

        let subdocumentsRef = db.collection("friendRequests").document(user.uid).collection("sent")
        subdocumentsRef.getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching subdocuments: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else {
                print("No subdocuments found to delete")
                return
            }

            for document in documents {
                if document.documentID == user.uid {
                    document.reference.delete { error in
                        if let error = error {
                            print("Error removing subdocument: \(error.localizedDescription)")
                        } else {
                            print("Subdocument successfully removed!")
                        }
                    }
                }
            }
        }

        deleteProfilePictureFromStorage(for: user)

        deleteUserDocumentFromFirestore(for: user)

        user.delete { error in
            if let error = error {
                print("Error deleting account: \(error.localizedDescription)")
            } else {
                print("Account deleted successfully")
            }
        }
    }
    func deleteProfilePictureFromStorage(for user: User) {
        let userId = user.uid
        let storageRef = Storage.storage().reference().child("profile_pictures/\(userId).jpg")

        storageRef.delete { error in
            if let error = error {
                print("Error deleting profile picture from Storage: \(error.localizedDescription)")
            } else {
                print("Profile picture deleted from Storage")
            }
        }
    }

    func deleteUserDocumentFromFirestore(for user: User) {
        let userId = user.uid
        let db = Firestore.firestore()
        let userProfileRef = db.collection("userProfiles").document(userId)

        userProfileRef.delete { error in
            if let error = error {
                print("Error deleting user document from Firestore: \(error.localizedDescription)")
            } else {
                print("User document deleted from Firestore")
            }
        }
    }

    
}

