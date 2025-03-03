import Foundation
import FirebaseAuth

struct Player: Codable, Identifiable {
    let id: String
    let email: String
    let displayName: String
    var eloRating: Int
    var matchesPlayed: Int
    var matchesWon: Int
    var matchesLost: Int
    
    init(id: String, email: String, displayName: String, eloRating: Int = 1200, matchesPlayed: Int = 0, matchesWon: Int = 0, matchesLost: Int = 0) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.eloRating = eloRating
        self.matchesPlayed = matchesPlayed
        self.matchesWon = matchesWon
        self.matchesLost = matchesLost
    }
    
    static func create(id: String, email: String, displayName: String) -> Player {
        Player(id: id, email: email, displayName: displayName)
    }
    
    static func createNew(email: String, name: String) -> Player {
        Player(
            id: UUID().uuidString,
            email: email,
            displayName: name
        )
    }
    
    static func fromFirebaseUser(_ user: User) -> Player {
        Player(
            id: user.uid,
            email: user.email ?? "",
            displayName: user.displayName ?? user.email ?? "Unknown"
        )
    }
    
    // Computed property to maintain compatibility with code using 'name'
    var name: String {
        displayName
    }
} 