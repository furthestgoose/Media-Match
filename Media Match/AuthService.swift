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
        
        // Check if the password is at least 12 characters long
        guard password.count >= 6 else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Password must be at least 6 characters long."])
            completion(error)
            return
        }
        
        // Check if the password contains at least one uppercase letter
        let uppercaseLetterRegex = ".*[A-Z]+.*"
        let uppercaseLetterTest = NSPredicate(format: "SELF MATCHES %@", uppercaseLetterRegex)
        guard uppercaseLetterTest.evaluate(with: password) else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Password must contain at least one uppercase letter."])
            completion(error)
            return
        }
        
        // Check if the password contains at least one number
        let numberRegex = ".*[0-9]+.*"
        let numberTest = NSPredicate(format: "SELF MATCHES %@", numberRegex)
        guard numberTest.evaluate(with: password) else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Password must contain at least one number."])
            completion(error)
            return
        }
        
        // Check if the password contains at least one special character
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
                    // Check the error code and handle it accordingly
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
                
                // Handle successful sign in
                print("Sign in successful!")
                
                // Add user data to Firestore
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
    // Traditional sign in with password and email
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
        
        // Check if the password contains at least one uppercase letter
        let uppercaseLetterRegex = ".*[A-Z]+.*"
        let uppercaseLetterTest = NSPredicate(format: "SELF MATCHES %@", uppercaseLetterRegex)
        guard uppercaseLetterTest.evaluate(with: password) else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Password must contain at least one uppercase letter."])
            completion(error)
            return
        }
        
        // Check if the password contains at least one number
        let numberRegex = ".*[0-9]+.*"
        let numberTest = NSPredicate(format: "SELF MATCHES %@", numberRegex)
        guard numberTest.evaluate(with: password) else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Password must contain at least one number."])
            completion(error)
            return
        }
        
        // Check if the password contains at least one special character
        let specialCharacterRegex = ".*[!@#$&*]+.*"
        let specialCharacterTest = NSPredicate(format: "SELF MATCHES %@", specialCharacterRegex)
        guard specialCharacterTest.evaluate(with: password) else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Password must contain at least one special character."])
            completion(error)
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                if let error = error as NSError? {
                    // Check the error code and handle it accordingly
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
                // Handle successful sign in
                print("Sign in successful!")
            }
    }



    
    //MARK: Regular password acount sign out.
    // Closure has whether sign out was successful or not
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

            // Create Google Sign In configuration object.
            let config = GIDConfiguration(clientID: clientID)
            
            // As you’re not using view controllers to retrieve the presentingViewController, access it through
            // the shared instance of the UIApplication
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            guard let rootViewController = windowScene.windows.first?.rootViewController else { return }

            // Start the sign in flow!
            GIDSignIn.sharedInstance.signIn(with: config, presenting: rootViewController) { [unowned self] user, error in

              if let error = error {
                  print("Error doing Google Sign-In, \(error)")
                  return
              }

              guard
                let authentication = user?.authentication,
                let idToken = authentication.idToken
              else {
                print("Error during Google Sign-In authentication, \(error)")
                return
              }

              let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                             accessToken: authentication.accessToken)
                
                
                // Authenticate with Firebase
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let e = error {
                        print(e.localizedDescription)
                    }
                   
                    print("Signed in with Google")
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
                        // Check the error code and handle it accordingly
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
                    // Handle successful sign in
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

        // Delete profile picture from Firebase Storage
        deleteProfilePictureFromStorage(for: user)

        // Delete user document from Firestore
        deleteUserDocumentFromFirestore(for: user)

        // Delete user account
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

