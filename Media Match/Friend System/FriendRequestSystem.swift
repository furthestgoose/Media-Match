

import Foundation
import FirebaseAuth
import FirebaseFirestore

class FriendService {
    static let shared = FriendService()

    private init() {}

    private let userProfilesCollection = "userProfiles"
    private let friendRequestsCollection = "friendRequests"
    private let sentSubcollection = "sent"
    
    func loadFriends(completion: @escaping ([UserProfile]) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            print("No user signed in.")
            completion([])
            return
        }

        let db = Firestore.firestore()
        let userProfileRef = db.collection(userProfilesCollection).document(currentUser.uid)

        userProfileRef.getDocument { snapshot, error in
            if let error = error {
                completion([])
                return
            }

            guard let document = snapshot, document.exists else {
                completion([])
                return
            }

            let data = document.data() ?? [:]
            let friendUserIDs = data["friends"] as? [String] ?? []

            let dispatchGroup = DispatchGroup()
            var friends: [UserProfile] = []

            for friendUserID in friendUserIDs {
                dispatchGroup.enter()
                self.loadUserProfile(for: friendUserID) { userProfile in
                    if let userProfile = userProfile {
                        friends.append(userProfile)
                    }
                    dispatchGroup.leave()
                }
            }

            dispatchGroup.notify(queue: .main) {
                completion(friends)
            }
        }
    }


    // MARK: - Friend Requests
    func sendFriendRequest(to receiverUserID: String, completion: @escaping (Error?) -> Void) {
            guard let currentUser = Auth.auth().currentUser else {
                completion(FriendServiceError.noUserSignedIn)
                return
            }

            guard !receiverUserID.isEmpty else {
                completion(FriendServiceError.invalidReceiverUserID)
                return
            }

            let db = Firestore.firestore()
            let requestData: [String: Any] = [
                "senderUserID": currentUser.uid,
                "receiverUserID": receiverUserID,
                "timestamp": Date().timeIntervalSince1970
            ]

            let friendRequestRef = db.collection(friendRequestsCollection).document(currentUser.uid).collection(sentSubcollection).document(receiverUserID)

            friendRequestRef.setData(requestData, merge: true) { error in
                completion(error)
            }
        }
    func acceptFriendRequest(from userId: String, completion: @escaping (Error?) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(FriendServiceError.noUserSignedIn)
            return
        }

        let db = Firestore.firestore()
        let friendRef = db.collection(userProfilesCollection).document(userId)
        let userRef = db.collection(userProfilesCollection).document(currentUser.uid)

        db.runTransaction { transaction, errorPointer in
            transaction.updateData(["friends": FieldValue.arrayUnion([currentUser.uid])], forDocument: friendRef)
            transaction.updateData(["friends": FieldValue.arrayUnion([userId])], forDocument: userRef)
            return nil
        } completion: { _, error in
            if let error = error {
                completion(error)
            } else {
                self.deleteRequest(for: userId)
                completion(nil)
            }
        }
    }

    func declineFriendRequest(from userId: String, completion: @escaping (Error?) -> Void) {
        
        deleteRequest(for: userId)
        completion(nil)
    }

    func deleteRequest(for userId: String) {
        guard let currentUser = Auth.auth().currentUser else {
            return
        }

        let db = Firestore.firestore()
        
        let requestRef = db.collection(friendRequestsCollection)
            .document(userId)
            .collection(sentSubcollection)
            .whereField("receiverUserID", isEqualTo: currentUser.uid)
        
        requestRef.getDocuments { (snapshot, error) in
            if let error = error {
                return
            }

            guard let documents = snapshot?.documents else {
                return
            }

            for document in documents {
                document.reference.delete { error in
                    if let error = error {
                        print("Error removing document: \(error.localizedDescription)")
                    } else {
                        print("Document successfully removed!")
                    }
                }
            }
        }
    }

    func removeFriend(userId: String, completion: @escaping (Error?) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(FriendServiceError.noUserSignedIn)
            return
        }

        let db = Firestore.firestore()
        let friendRef = db.collection(userProfilesCollection).document(userId)
        let userRef = db.collection(userProfilesCollection).document(currentUser.uid)
        
        let dispatchGroup = DispatchGroup()

        dispatchGroup.enter()
        friendRef.updateData(["friends": FieldValue.arrayRemove([currentUser.uid])]) { error in
            dispatchGroup.leave()
            if let error = error {
                completion(error)
                return
            }
        }

        dispatchGroup.enter()
        userRef.updateData(["friends": FieldValue.arrayRemove([userId])]) { error in
            dispatchGroup.leave()
            if let error = error {
                completion(error)
                return
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(nil)
        }
    }

    // MARK: - Load Requests
    func loadOutgoingRequests(completion: @escaping ([UserProfile]) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion([])
            return
        }

        let db = Firestore.firestore()
        let outgoingRequestsRef = db.collection("friendRequests").document(currentUser.uid).collection("sent")

        outgoingRequestsRef.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching outgoing friend requests: \(error.localizedDescription)")
                completion([])
                return
            }

            guard let documents = snapshot?.documents else {
                completion([])
                return
            }
            

            let dispatchGroup = DispatchGroup()
            var profiles: [UserProfile] = []

            for document in documents {
                let data = document.data()
                if let receiverUserID = data["receiverUserID"] as? String {
                    dispatchGroup.enter()
                    self.loadUserProfile(for: receiverUserID) { userProfile in
                        if let userProfile = userProfile {
                            profiles.append(userProfile)
                        }
                        dispatchGroup.leave()
                    }
                }
            }

            dispatchGroup.notify(queue: .main) {
                completion(profiles)
            }
        }
    }

    func loadIncomingRequests(completion: @escaping ([UserProfile]) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion([])
            return
        }

        let db = Firestore.firestore()
        let incomingRequestsRef = db.collectionGroup(sentSubcollection).whereField("receiverUserID", isEqualTo: currentUser.uid)

        incomingRequestsRef.getDocuments { snapshot, error in
            if let error = error {
                completion([])
                return
            }

            guard let documents = snapshot?.documents else {
                completion([])
                return
            }

            let dispatchGroup = DispatchGroup()
            var profiles: [UserProfile] = []

            for document in documents {
                let data = document.data()
                if let senderUserID = data["senderUserID"] as? String {
                    dispatchGroup.enter()
                    self.loadUserProfile(for: senderUserID) { userProfile in
                        if let userProfile = userProfile {
                            profiles.append(userProfile)
                        }
                        dispatchGroup.leave()
                    }
                }
            }

            dispatchGroup.notify(queue: .main) {
                completion(profiles)
            }
        }
    }



    // MARK: - User Profiles
    func loadUserProfile(for userID: String, completion: @escaping (UserProfile?) -> Void) {
        let db = Firestore.firestore()
        let userProfileRef = db.collection(userProfilesCollection).document(userID)

        userProfileRef.getDocument { snapshot, error in
            if let error = error {
                completion(nil)
                return
            }

            guard let document = snapshot, document.exists else {
                completion(nil)
                return
            }

            let profile = self.mapDocumentToUserProfile(document)
            completion(profile)
        }
    }

    func searchForFriend(username: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        let db = Firestore.firestore()
        let userProfilesRef = db.collection(userProfilesCollection)

        userProfilesRef.whereField("username", isEqualTo: username).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let document = snapshot?.documents.first else {
                completion(.failure(FriendServiceError.userNotFound))
                return
            }

            let profile = self.mapDocumentToUserProfile(document)
            completion(.success(profile))
        }
    }

    // MARK: - Helper Methods
    private func mapDocumentToUserProfile(_ document: DocumentSnapshot) -> UserProfile {
        let data = document.data() ?? [:]
        let userId = document.documentID
        let username = data["username"] as? String ?? ""
        let profilePictureURL = data["profilePictureURL"] as? String
        let likedItems = data["likedItems"] as? [String] ?? []
        let friends = data["friends"] as? [String] ?? []

        return UserProfile(userId: userId, username: username, profilePictureURL: profilePictureURL, likedItems: likedItems, friends: friends)
    }
}

// MARK: - Error Handling
enum FriendServiceError: Error {
    case noUserSignedIn
    case invalidReceiverUserID
    case userNotFound
}
