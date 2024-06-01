import Foundation
import FirebaseCore
import FirebaseAuth
import CryptoKit
import AuthenticationServices
import GoogleSignIn


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
    func regularCreateAccount(email: String, password: String, completion: @escaping (Error?) -> Void) {
        
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
        
        // Proceed with account creation if the password is valid
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
                return
            }
            // Handle successful sign in
            print("Sign in successful!")
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



    
    // Regular password acount sign out.
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
    // Sign out if used Single-sign-on with Google
    func googleSignOut() {
        GIDSignIn.sharedInstance.signOut()
        print("Google sign out")
    }
    
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
    
}

