import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @EnvironmentObject var authService: AuthService
    @State private var emailErrorMessage: String? = nil
    @State private var passwordErrorMessage: String? = nil
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
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
                    }label: {
                        Image("GoogleButton")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 300)
                    }
                    .padding(.top, 100)
                    
                    Text("OR")
                        .padding()
                    
                    HStack {
                        Spacer()
                        VStack {
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
                    
                    Button("Login") {
                        authService.regularSignIn(email: email, password: password) { error in
                            if let error = error {
                                let errorMessage = error.localizedDescription
                                if errorMessage.contains("email") {
                                    self.emailErrorMessage = errorMessage
                                    self.passwordErrorMessage = nil
                                } else if errorMessage.contains("Password") {
                                    self.passwordErrorMessage = errorMessage
                                    self.emailErrorMessage = nil
                                } else {
                                    self.emailErrorMessage = nil
                                    self.passwordErrorMessage = nil
                                }
                            } else {
                                self.emailErrorMessage = nil
                                self.passwordErrorMessage = nil
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding()
                    
                    
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Text("Create Account").foregroundColor(.blue)
                        }
                    }.frame(maxWidth: .infinity, alignment: .center)
                    HStack{
                        NavigationLink(destination: passwordResetView()) {
                            Text("Reset your password").foregroundColor(.blue)
                        }
                    }.frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
    
    struct LoginView_Previews: PreviewProvider {
        static var previews: some View {
            LoginView()
        }
    }
    
