import Foundation
import FirebaseFirestore
import FirebaseAuth

class MatchmakingService: ObservableObject {
    @Published var currentQueue: MatchQueue?
    @Published var matchFound: Match?
    @Published var isSearching = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    private var queueListener: ListenerRegistration?
    private var matchListener: ListenerRegistration?
    
    private let MAX_RATING_DIFFERENCE = 400.0 // Maximum ELO difference for matching
    private let RATING_EXPANSION_RATE = 50.0 // How much to expand rating range per 30 seconds
    private let MAX_QUEUE_TIME = 300.0 // Maximum time in queue (5 minutes)
    
    deinit {
        stopListening()
    }
    
    /// Start searching for a match
    func startMatchmaking(for player: Player) async throws {
        guard !isSearching else { return }
        
        print("MatchmakingService: Starting matchmaking for \(player.name)")
        isSearching = true
        error = nil
        
        // Create queue entry
        let queueEntry = MatchQueueEntry(
            playerId: player.id!,
            playerName: player.name,
            eloRating: player.eloRating
        )
        
        // Add to queue collection
        try db.collection("matchmaking")
            .document(player.id!)
            .setData(from: queueEntry)
        
        // Start listening for matches
        startListening(for: player)
    }
    
    /// Cancel matchmaking
    func cancelMatchmaking(for playerId: String) async throws {
        print("MatchmakingService: Canceling matchmaking for \(playerId)")
        
        try await db.collection("matchmaking")
            .document(playerId)
            .delete()
        
        stopListening()
        isSearching = false
        currentQueue = nil
        matchFound = nil
    }
    
    /// Accept a match
    func acceptMatch(match: Match) async throws {
        print("MatchmakingService: Accepting match")
        
        try await db.collection("matchmaking")
            .document(Auth.auth().currentUser!.uid)
            .updateData(["matchAccepted": true])
    }
    
    // MARK: - Private Methods
    
    private func startListening(for player: Player) {
        print("MatchmakingService: Starting listeners")
        
        // Listen to own queue entry
        queueListener = db.collection("matchmaking")
            .document(player.id!)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("MatchmakingService: Queue listener error - \(error.localizedDescription)")
                    self?.error = error.localizedDescription
                    return
                }
                
                guard let snapshot = snapshot, snapshot.exists,
                      let queue = try? snapshot.data(as: MatchQueue.self) else {
                    self?.currentQueue = nil
                    return
                }
                
                self?.currentQueue = queue
                
                // If match is found, start listening to match document
                if let matchId = queue.matchId {
                    self?.listenToMatch(matchId: matchId)
                }
            }
        
        // Start matchmaking process
        Task {
            do {
                try await findMatch(for: player)
            } catch {
                print("MatchmakingService: Matchmaking error - \(error.localizedDescription)")
                self.error = error.localizedDescription
            }
        }
    }
    
    private func stopListening() {
        queueListener?.remove()
        queueListener = nil
        matchListener?.remove()
        matchListener = nil
    }
    
    private func listenToMatch(matchId: String) {
        matchListener?.remove()
        matchListener = db.collection("matches")
            .document(matchId)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("MatchmakingService: Match listener error - \(error.localizedDescription)")
                    self?.error = error.localizedDescription
                    return
                }
                
                guard let snapshot = snapshot, snapshot.exists,
                      let match = try? snapshot.data(as: Match.self) else {
                    self?.matchFound = nil
                    return
                }
                
                self?.matchFound = match
            }
    }
    
    private func findMatch(for player: Player) async throws {
        let playerId = player.id!
        let playerRating = player.eloRating
        
        // Query for potential matches
        let snapshot = try await db.collection("matchmaking")
            .whereField("matchFound", isEqualTo: false)
            .getDocuments()
        
        let potentialMatches = snapshot.documents.compactMap { document -> (MatchQueue, Double)? in
            guard let queue = try? document.data(as: MatchQueue.self),
                  queue.playerId != playerId else { return nil }
            
            let ratingDiff = abs(queue.playerRating - Double(playerRating))
            let timeInQueue = Date().timeIntervalSince(queue.startTime)
            let adjustedRatingDiff = ratingDiff - (timeInQueue / 30.0 * RATING_EXPANSION_RATE)
            
            return (queue, adjustedRatingDiff)
        }
        
        // Sort by rating difference and find best match
        let sortedMatches = potentialMatches.sorted { $0.1 < $1.1 }
        
        if let bestMatch = sortedMatches.first,
           bestMatch.1 <= MAX_RATING_DIFFERENCE {
            // Create match
            try await createMatch(player1Id: playerId, player2Id: bestMatch.0.playerId)
        }
    }
    
    private func createMatch(player1Id: String, player2Id: String) async throws {
        let batch = db.batch()
        
        // Update both players' queue entries
        let matchId = db.collection("matches").document().documentID
        
        let player1Ref = db.collection("matchmaking").document(player1Id)
        let player2Ref = db.collection("matchmaking").document(player2Id)
        
        batch.updateData([
            "matchFound": true,
            "matchId": matchId
        ], forDocument: player1Ref)
        
        batch.updateData([
            "matchFound": true,
            "matchId": matchId
        ], forDocument: player2Ref)
        
        try await batch.commit()
    }
} 