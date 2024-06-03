//
//  StartView.swift
//  Media Match
//
//  Created by Adam Byford on 01/06/2024.
//

import SwiftUI
import FirebaseAuth

struct StartView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        if authService.signedIn {
            MainView()
        } else {
            WelcomeView()
        }
    }
}

struct StartView_Previews: PreviewProvider {
    @StateObject static var authService = AuthService()

    static var previews: some View {
        if authService.signedIn {
            MainView()
        } else {
            WelcomeView()
        }
    }
}
