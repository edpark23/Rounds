import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine
import SwiftUI

@MainActor
class MatchService: ObservableObject {
    static private var _shared: MatchService?
    static var shared: MatchService {
        get async {
            if let service = _shared {
                return service
            }
            let service = await MatchService(authService: await AuthenticationService.shared)
            _shared = service
            return service
        }
    }
    
    private let authService: AuthenticationService
    private let eloService: ELOService
    private let db = Firestore.firestore()
    
    @Published var currentMatch: Match?
    @Published var recentMatches: [Match] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var matchHistory: [Match] = []
    
    init(authService: AuthenticationService) async {
        self.authService = authService
        self.eloService = await ELOService.shared
    }
    
    /// Create and process a new match
    /// - Parameters:
    ///   - player1: First player
    ///   - player2: Second player
    ///   - course: The golf course
    ///   - tee: The tee
    /// - Returns: The processed match with updated ratings
    func createMatch(player1: Player, player2: Player, course: GolfCourse, tee: GolfCourse.Scorecard.Tee) async throws -> Match {
        guard authService.currentUser != nil else {
            throw AuthenticationError.notLoggedIn
        }
        
        let match = Match(
            player1Id: player1.id,
            player2Id: player2.id,
            player1Name: player1.displayName,
            player2Name: player2.displayName,
            courseId: course.id,
            courseName: course.name,
            selectedTee: tee.name,
            courseRating: tee.rating,
            courseSlope: tee.slope
        )
        
        try await saveMatch(match)
        return match
    }
    
    /// Submit scores for a match
    /// - Parameters:
    ///   - match: The match to update
    ///   - player1Score: Score of the first player
    ///   - player2Score: Score of the second player
    func submitScores(match: Match, player1Score: Int, player2Score: Int) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let winner: Player
        let loser: Player
        let winnerScore: Int
        let loserScore: Int
        
        // Get player objects
        let player1 = try await db.collection("players").document(match.player1Id).getDocument(as: Player.self)
        let player2 = try await db.collection("players").document(match.player2Id).getDocument(as: Player.self)
        
        // Determine winner and loser
        if player1Score < player2Score {
            winner = player1
            loser = player2
            winnerScore = player1Score
            loserScore = player2Score
        } else {
            winner = player2
            loser = player1
            winnerScore = player2Score
            loserScore = player1Score
        }
        
        // Calculate ELO changes
        let eloChange = eloService.calculateEloChange(
            winnerRating: winner.eloRating,
            loserRating: loser.eloRating,
            scoreDifferential: abs(player1Score - player2Score)
        )
        
        // Update winner stats
        let updatedWinner = Player(
            id: winner.id,
            email: winner.email,
            displayName: winner.displayName,
            eloRating: Int(round(Double(winner.eloRating) + Double(eloChange))),
            matchesPlayed: winner.matchesPlayed + 1,
            matchesWon: winner.matchesWon + 1,
            matchesLost: winner.matchesLost
        )
        
        // Update loser stats
        let updatedLoser = Player(
            id: loser.id,
            email: loser.email,
            displayName: loser.displayName,
            eloRating: Int(round(Double(loser.eloRating) - Double(eloChange))),
            matchesPlayed: loser.matchesPlayed + 1,
            matchesWon: loser.matchesWon,
            matchesLost: loser.matchesLost + 1
        )
        
        // Start a transaction
        try await db.runTransaction { [self] transaction, _ in
            // Update players
            let winnerRef = self.db.collection("players").document(winner.id)
            let loserRef = self.db.collection("players").document(loser.id)
            
            // Get current player data
            guard let winnerDoc = try? transaction.getDocument(winnerRef),
                  let loserDoc = try? transaction.getDocument(loserRef),
                  let winnerData = winnerDoc.data(),
                  let loserData = loserDoc.data() else {
                return nil
            }
            
            // Update winner
            transaction.updateData([
                "eloRating": updatedWinner.eloRating,
                "matchCount": FieldValue.increment(Int64(1)),
                "winCount": FieldValue.increment(Int64(1))
            ], forDocument: winnerRef)
            
            // Update loser
            transaction.updateData([
                "eloRating": updatedLoser.eloRating,
                "matchCount": FieldValue.increment(Int64(1))
            ], forDocument: loserRef)
            
            // Update match
            let matchRef = self.db.collection("matches").document(match.id)
            var matchData = try await matchRef.getDocument().data() ?? [:]
            matchData["winner"] = winner.id
            matchData["loser"] = loser.id
            matchData["winnerScore"] = winnerScore
            matchData["loserScore"] = loserScore
            matchData["winnerRatingChange"] = eloChange
            matchData["loserRatingChange"] = -eloChange
            matchData["status"] = "completed"
            
            // Perform updates in transaction
            transaction.updateData(matchData, forDocument: matchRef)
            
            return nil
        }
        
        // Update local state
        await MainActor.run {
            self.currentMatch = nil
        }
    }
    
    /// Save a match
    /// - Parameter match: The match to save
    func saveMatch(_ match: Match) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let matchRef = db.collection("matches").document(match.id)
        let data = try JSONEncoder().encode(match)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        try await matchRef.setData(dict)
    }
    
    /// Fetch recent matches for a player
    /// - Parameter playerId: The ID of the player
    /// - Returns: Array of recent matches
    func fetchRecentMatches(for playerId: String, limit: Int = 10) async throws -> [Match] {
        isLoading = true
        defer { isLoading = false }
        
        let matches = try await db.collection("matches")
            .whereFilter(Filter.orFilter([
                Filter.whereField("player1Id", isEqualTo: playerId),
                Filter.whereField("player2Id", isEqualTo: playerId)
            ]))
            .order(by: "date", descending: true)
            .limit(to: limit)
            .getDocuments()
            .documents
            .compactMap { try? $0.data(as: Match.self) }
        
        await MainActor.run {
            self.recentMatches = matches
        }
        
        return matches
    }
    
    /// Fetch matches for the current user
    /// - Returns: Array of matches
    func fetchUserMatches() async throws -> [Match] {
        guard let currentUser = authService.currentUser else {
            throw AuthenticationError.notLoggedIn
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let matches = try await db.collection("matches")
            .whereFilter(Filter.orFilter([
                Filter.whereField("player1Id", isEqualTo: currentUser.id),
                Filter.whereField("player2Id", isEqualTo: currentUser.id)
            ]))
            .order(by: "date", descending: true)
            .getDocuments()
            .documents
            .compactMap { try? $0.data(as: Match.self) }
        
        await MainActor.run {
            self.matchHistory = matches
        }
        
        return matches
    }
    
    @MainActor
    func updateMatch(_ match: Match) async throws {
        let matchRef = db.collection("matches").document(match.id)
        let data = try JSONEncoder().encode(match)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        try await matchRef.setData(dict)
    }
    
    func startMatch(opponent: Player, course: GolfCourse, tee: GolfCourse.Scorecard.Tee) async throws {
        guard let currentUser = authService.currentUser else {
            throw AuthenticationError.notLoggedIn
        }
        
        let match = try await createMatch(
            player1: currentUser,
            player2: opponent,
            course: course,
            tee: tee
        )
        
        await MainActor.run {
            self.currentMatch = match
        }
    }
} 