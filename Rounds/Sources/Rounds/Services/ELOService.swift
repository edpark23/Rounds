import Foundation
import FirebaseFirestore

@MainActor
class ELOService {
    static private var _shared: ELOService?
    static var shared: ELOService {
        get async {
            if let service = _shared {
                return service
            }
            let service = await ELOService()
            _shared = service
            return service
        }
    }
    
    // Constants for ELO calculation
    private static let K_FACTOR_NEW_PLAYER = 40.0 // Higher K-factor for new players (< 10 games)
    private static let K_FACTOR_STANDARD = 20.0 // Standard K-factor
    private static let K_FACTOR_ESTABLISHED = 10.0 // Lower K-factor for established players (> 30 games)
    
    private static let RATING_FLOOR = 100.0 // Minimum possible rating
    private static let PROVISIONAL_GAMES_THRESHOLD = 10 // Number of games before player is no longer provisional
    private static let ESTABLISHED_GAMES_THRESHOLD = 30 // Number of games before player is considered established
    
    private let db = Firestore.firestore()
    
    private let BASE_K_FACTOR: Double = 32.0
    private let SCORE_DIFFERENTIAL_MULTIPLIER: Double = 0.5
    private let MAX_SCORE_DIFFERENTIAL_BONUS: Double = 16.0
    
    private init() async {
        print("ELOService: Initializing...")
    }
    
    struct ELOUpdate {
        let oldRating: Double
        let newRating: Double
        let change: Double
    }
    
    /// Calculate new ELO ratings for both players after a match
    /// - Parameters:
    ///   - winner: The winning player
    ///   - loser: The losing player
    ///   - scoreDifferential: Optional score differential (can affect rating change)
    /// - Returns: Tuple containing rating updates for both players
    func calculateMatchResult(winner: Player, loser: Player, scoreDifferential: Int? = nil) -> (winner: ELOUpdate, loser: ELOUpdate) {
        // Calculate expected scores
        let expectedWinnerScore = expectedScore(playerRating: Double(winner.eloRating), opponentRating: Double(loser.eloRating))
        let expectedLoserScore = 1.0 - expectedWinnerScore
        
        // Calculate actual scores
        let actualWinnerScore = 1.0
        let actualLoserScore = 0.0
        
        // Calculate K-factor adjustments
        var winnerK = BASE_K_FACTOR
        var loserK = BASE_K_FACTOR
        
        if let differential = scoreDifferential {
            let bonus = min(Double(differential) * SCORE_DIFFERENTIAL_MULTIPLIER, MAX_SCORE_DIFFERENTIAL_BONUS)
            winnerK += bonus
            loserK += bonus
        }
        
        // Calculate rating changes
        let winnerRatingChange = winnerK * (actualWinnerScore - expectedWinnerScore)
        let loserRatingChange = loserK * (actualLoserScore - expectedLoserScore)
        
        // Calculate new ratings
        let newWinnerRating = max(Self.RATING_FLOOR, Double(winner.eloRating) + winnerRatingChange)
        let newLoserRating = max(Self.RATING_FLOOR, Double(loser.eloRating) + loserRatingChange)
        
        return (
            winner: ELOUpdate(
                oldRating: Double(winner.eloRating),
                newRating: newWinnerRating,
                change: winnerRatingChange
            ),
            loser: ELOUpdate(
                oldRating: Double(loser.eloRating),
                newRating: newLoserRating,
                change: loserRatingChange
            )
        )
    }
    
    /// Update player ratings in Firestore after a match
    /// - Parameters:
    ///   - winner: The winning player
    ///   - loser: The losing player
    ///   - scoreDifferential: Optional score differential
    func updateRatings(winner: Player, loser: Player, scoreDifferential: Int? = nil) async throws {
        let updates = calculateMatchResult(winner: winner, loser: loser, scoreDifferential: scoreDifferential)
        
        // Create batch update
        let batch = db.batch()
        
        // Update winner
        let winnerRef = db.collection("players").document(winner.id)
        batch.updateData([
            "eloRating": updates.winner.newRating,
            "matchCount": FieldValue.increment(Int64(1)),
            "winCount": FieldValue.increment(Int64(1))
        ], forDocument: winnerRef)
        
        // Update loser
        let loserRef = db.collection("players").document(loser.id)
        batch.updateData([
            "eloRating": updates.loser.newRating,
            "matchCount": FieldValue.increment(Int64(1))
        ], forDocument: loserRef)
        
        // Commit the batch
        try await batch.commit()
    }
    
    // MARK: - Private Helper Methods
    
    private func expectedScore(playerRating: Double, opponentRating: Double) -> Double {
        // Standard ELO expectancy formula
        1.0 / (1.0 + pow(10.0, (opponentRating - playerRating) / 400.0))
    }
    
    private func kFactor(for player: Player) -> Double {
        if player.matchesPlayed < Self.PROVISIONAL_GAMES_THRESHOLD {
            return Self.K_FACTOR_NEW_PLAYER
        } else if player.matchesPlayed < Self.ESTABLISHED_GAMES_THRESHOLD {
            return Self.K_FACTOR_STANDARD
        } else {
            return Self.K_FACTOR_ESTABLISHED
        }
    }
    
    private func calculateScoreImpact(scoreDifferential: Int?) -> Double {
        guard let differential = scoreDifferential else { return 1.0 }
        
        // Increase rating change based on score differential
        // Maximum impact is 1.5x for very large differentials
        let impact = 1.0 + min(Double(differential) / 10.0, 0.5)
        return impact
    }
    
    private let kFactor = 32.0
    private let baseRating = 1500.0
    
    func calculateEloChange(
        winnerRating: Int,
        loserRating: Int,
        scoreDifferential: Int
    ) -> Int {
        let expectedScore = 1.0 / (1.0 + pow(10.0, Double(loserRating - winnerRating) / 400.0))
        let actualScore = 1.0
        
        // Apply score differential bonus (max 25% bonus for large differentials)
        let bonus = min(Double(scoreDifferential) / 100.0, 0.25)
        let adjustedKFactor = kFactor * (1.0 + bonus)
        
        let change = Int(round(adjustedKFactor * (actualScore - expectedScore)))
        return change
    }
    
    func getInitialRating() -> Int {
        return Int(baseRating)
    }
} 