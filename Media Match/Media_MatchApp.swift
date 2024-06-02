//
//  Media_MatchApp.swift
//  Media Match
//
//  Created by Adam Byford on 01/06/2024.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}
@main
struct Media_MatchApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var authService = AuthService()
    var body: some Scene {
        WindowGroup {
            StartView()
                .environmentObject(authService)
        }
    }
}

