import Foundation
import FirebaseFirestore

class LeaderboardService: ObservableObject {
    @Published var players: [Player] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    init() {
        startListening()
    }
    
    deinit {
        stopListening()
    }
    
    func startListening() {
        print("LeaderboardService: Starting real-time updates")
        isLoading = true
        
        // Listen for real-time updates, ordered by ELO rating
        listener = db.collection("players")
            .order(by: "eloRating", descending: true)
            .limit(to: 100) // Limit to top 100 players
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("LeaderboardService: Error fetching players - \(error.localizedDescription)")
                    self.error = error.localizedDescription
                    return
                }
                
                guard let snapshot = snapshot else {
                    print("LeaderboardService: No snapshot received")
                    return
                }
                
                do {
                    self.players = try snapshot.documents.compactMap { document in
                        try document.data(as: Player.self)
                    }
                    print("LeaderboardService: Updated players list - Count: \(self.players.count)")
                } catch {
                    print("LeaderboardService: Error decoding players - \(error.localizedDescription)")
                    self.error = error.localizedDescription
                }
                
                self.isLoading = false
            }
    }
    
    func stopListening() {
        print("LeaderboardService: Stopping real-time updates")
        listener?.remove()
        listener = nil
    }
    
    func searchPlayers(query: String) async throws -> [Player] {
        print("LeaderboardService: Searching players with query: \(query)")
        let snapshot = try await db.collection("players")
            .whereField("displayName", isGreaterThanOrEqualTo: query)
            .whereField("displayName", isLessThanOrEqualTo: query + "\u{f8ff}")
            .order(by: "displayName")
            .limit(to: 20)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: Player.self)
        }
    }
} 