//
//  UserProfile.swift
//  Media Match
//
//  Created by Adam Byford on 02/06/2024.
//

import Foundation

struct UserProfile: Identifiable {
    var id: String { userId }
    var userId: String
    var username: String
    var profilePictureURL: String?
    var likedItems: [String]
}
