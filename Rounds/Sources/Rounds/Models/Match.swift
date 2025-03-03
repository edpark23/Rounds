import Foundation
import FirebaseFirestore

struct Match: Identifiable, Codable, Equatable {
    let id: String
    let player1Id: String
    let player2Id: String
    let player1Name: String
    let player2Name: String
    var courseId: String
    var courseName: String
    var selectedTee: String
    var courseRating: Double
    var courseSlope: Int
    var player1Score: Int?
    var player2Score: Int?
    var winner: String?
    var eloChange: Int?
    let date: Date
    let startTime: Date
    var endTime: Date?
    var status: MatchStatus
    var tournamentId: String?
    var holes: [Int]?
    
    init(id: String = UUID().uuidString,
         player1Id: String,
         player2Id: String,
         player1Name: String,
         player2Name: String,
         courseId: String,
         courseName: String,
         selectedTee: String,
         courseRating: Double,
         courseSlope: Int,
         player1Score: Int? = nil,
         player2Score: Int? = nil,
         winner: String? = nil,
         eloChange: Int? = nil,
         date: Date = Date(),
         startTime: Date = Date(),
         endTime: Date? = nil,
         status: MatchStatus = .pending,
         tournamentId: String? = nil) {
        self.id = id
        self.player1Id = player1Id
        self.player2Id = player2Id
        self.player1Name = player1Name
        self.player2Name = player2Name
        self.courseId = courseId
        self.courseName = courseName
        self.selectedTee = selectedTee
        self.courseRating = courseRating
        self.courseSlope = courseSlope
        self.player1Score = player1Score
        self.player2Score = player2Score
        self.winner = winner
        self.eloChange = eloChange
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
        self.tournamentId = tournamentId
    }
    
    var isComplete: Bool {
        status == .completed
    }
    
    func playerScore(for playerId: String) -> Int? {
        if playerId == player1Id {
            return player1Score
        } else if playerId == player2Id {
            return player2Score
        }
        return nil
    }
    
    func opponentScore(for playerId: String) -> Int? {
        if playerId == player1Id {
            return player2Score
        } else if playerId == player2Id {
            return player1Score
        }
        return nil
    }
    
    func isWinner(_ playerId: String) -> Bool {
        winner == playerId
    }
    
    static func == (lhs: Match, rhs: Match) -> Bool {
        lhs.id == rhs.id
    }
} 