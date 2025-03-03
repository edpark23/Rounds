import Foundation
import FirebaseFirestore

struct MatchQueueEntry: Codable, Identifiable {
    var id: String?
    let playerId: String
    let playerName: String
    let eloRating: Int
    let timestamp: Date
    let status: QueueStatus
    
    enum QueueStatus: String, Codable {
        case searching
        case matched
        case cancelled
    }
    
    init(playerId: String, playerName: String, eloRating: Int, status: QueueStatus = .searching) {
        self.playerId = playerId
        self.playerName = playerName
        self.eloRating = eloRating
        self.timestamp = Date()
        self.status = status
    }
} 