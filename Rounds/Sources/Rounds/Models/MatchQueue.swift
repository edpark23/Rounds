import Foundation
import FirebaseFirestore

struct MatchQueue: Codable {
    var id: String?
    let playerId: String
    let playerName: String
    let playerRating: Double
    let startTime: Date
    var matchFound: Bool = false
    var matchId: String?
    var matchAccepted: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id
        case playerId
        case playerName
        case playerRating
        case startTime
        case matchFound
        case matchId
        case matchAccepted
    }
} 