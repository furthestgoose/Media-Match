import SwiftUI

struct passwordResetView: View {
    @State private var email: String = ""
    @EnvironmentObject var authService: AuthService
    @State private var emailErrorMessage: String? = nil
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
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
                    
                    
                    HStack {
                        Spacer()
                        VStack {
                            TextField("Email", text: $email)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                                .autocapitalization(.none)
                                .border(emailErrorMessage?.contains("Password") == true ? Color.green : (emailErrorMessage != nil ? Color.red : Color.clear), width: 1)
                                .frame(width: 300)
                            if let emailErrorMessage = emailErrorMessage {
                                Text(emailErrorMessage)
                                    .foregroundColor(emailErrorMessage.contains("Password") ? .green : .red)
                                    .font(.footnote)
                                    .padding(.top, 2)
                            }
                        }
                        Spacer()
                    }
                    
                    
                    
                    Button("Send Reset Email") {
                        authService.passwordReset(email: email) { error in
                            if let error = error {
                                let errorMessage = error.localizedDescription
                                if errorMessage.contains("email") || errorMessage.contains("Password") {
                                    self.emailErrorMessage = errorMessage
                                } else {
                                    self.emailErrorMessage = nil
                                }
                            } else {
                                self.emailErrorMessage = nil
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding()
                }
                .padding()
            }
        }
    }
    
    struct passwordResetView_Previews: PreviewProvider {
        static var previews: some View {
            passwordResetView()
        }
    }
}

