import SwiftUI
import Network

struct WelcomeView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var username: String = ""
    @State private var usernameErrorMessage: String? = nil
    @State private var emailErrorMessage: String? = nil
    @State private var passwordErrorMessage: String? = nil
    @EnvironmentObject var authService: AuthService
    @ObservedObject private var networkMonitor = NetworkMonitor()
    
    var body: some View {
        GeometryReader { geometry in
            let isIPad = geometry.size.width >= 748
            let scale = isIPad ? 1.5 : 1.0
            NavigationStack {
                ZStack {
                    LinearGradient(gradient: Gradient(colors: [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 0.9, green: 0.2, blue: 0.2)]),
                                   startPoint: .top,
                                   endPoint: .bottom)
                    .ignoresSafeArea()
                    .opacity(0.5)
                    
                    VStack {
                        Text("Media Match")
                            .font(.largeTitle)
                            .padding(.top, -70)
                            .foregroundColor(.white)
                        
                        
                        Image(systemName: "figure.2.circle")
                            .font(.system(size: 130))
                            .foregroundStyle(Color.white)
                            .padding(.top, -30)
                        
                        Button {
                            print("Tapped google sign in")
                            authService.googleSignIn()
                        } label: {
                            Image("GoogleButton")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 300)
                        }
                        .padding(.top, 20)
                        
                        Text("OR")
                            .padding()
                        
                        HStack {
                            Spacer()
                            VStack {
                                TextField("Username", text: $username)
                                    .textFieldStyle(.roundedBorder)
                                    .autocorrectionDisabled()
                                    .autocapitalization(.none)
                                    .border(usernameErrorMessage != nil ? Color.red : Color.clear)
                                if let usernameErrorMessage = usernameErrorMessage{
                                    Text(usernameErrorMessage)
                                        .foregroundColor(.red)
                                        .font(.footnote)
                                        .padding(.top, 2)
                                }
                                
                                TextField("Email", text: $email)
                                    .textFieldStyle(.roundedBorder)
                                    .autocorrectionDisabled()
                                    .autocapitalization(.none)
                                    .border(emailErrorMessage != nil ? Color.red : Color.clear)
                                if let emailErrorMessage = emailErrorMessage {
                                    Text(emailErrorMessage)
                                        .foregroundColor(.red)
                                        .font(.footnote)
                                        .padding(.top, 2)
                                }
                                
                                SecureField("Password", text: $password)
                                    .textFieldStyle(.roundedBorder)
                                    .autocorrectionDisabled()
                                    .autocapitalization(.none)
                                    .border(passwordErrorMessage != nil ? Color.red : Color.clear)
                                if let passwordErrorMessage = passwordErrorMessage {
                                    Text(passwordErrorMessage)
                                        .foregroundColor(.red)
                                        .font(.footnote)
                                        .padding(.top, 2)
                                }
                            }
                            .frame(width: 300)
                            Spacer()
                        }
                        
                        Button("Create an Account") {
                            authService.regularCreateAccount(email: email, password: password, username: username) { error in
                                if let error = error {
                                    let errorMessage = error.localizedDescription
                                    if errorMessage.contains("email") {
                                        self.usernameErrorMessage = nil
                                        self.emailErrorMessage = errorMessage
                                        self.passwordErrorMessage = nil
                                    } else if errorMessage.contains("Password") {
                                        self.usernameErrorMessage = nil
                                        self.passwordErrorMessage = errorMessage
                                        self.emailErrorMessage = nil
                                    } else if errorMessage.contains ("Username"){
                                        self.usernameErrorMessage = errorMessage
                                        self.passwordErrorMessage = nil
                                        self.emailErrorMessage = nil
                                    } else {
                                        self.usernameErrorMessage = nil
                                        self.emailErrorMessage = nil
                                        self.passwordErrorMessage = nil
                                    }
                                } else {
                                    self.usernameErrorMessage = nil
                                    self.emailErrorMessage = nil
                                    self.passwordErrorMessage = nil
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding()
                        
                        HStack {
                            Text("Already have an account? ")
                                .foregroundColor(.white)
                            
                            NavigationLink(destination: LoginView()) {
                                Text("Login").foregroundColor(.blue)
                            }
                        }.frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding()
                    .frame(maxWidth: isIPad ? geometry.size.width * 0.8 : .infinity, maxHeight: isIPad ? geometry.size.height * 0.8 : .infinity)
                    .scaleEffect(scale)
                }
            }
        }
        .disabled(!networkMonitor.isConnected)
        .noInternetOverlay()
    }
}

#Preview {
    WelcomeView()
}

