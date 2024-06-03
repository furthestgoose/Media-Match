//
//  FriendRequest.swift
//  Media Match
//
//  Created by Adam Byford on 02/06/2024.
//

import Foundation

struct FriendRequest: Identifiable {
    var id: String
    var fromUserId: String
    var toUserId: String
    var status: String // pending, accepted, rejected
}
