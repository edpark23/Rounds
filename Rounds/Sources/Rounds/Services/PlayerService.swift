import Foundation
import FirebaseFirestore

class PlayerService: ObservableObject {
    static let shared = PlayerService()
    private let db = Firestore.firestore()
    @Published private(set) var players: [String: Player] = [:]
    
    private init() {}
    
    func getPlayers(ids: [String]) async throws -> [Player] {
        var result: [Player] = []
        for id in ids {
            let player = try await getPlayer(id)
            result.append(player)
        }
        return result
    }
    
    func getPlayer(_ id: String) async throws -> Player {
        if let player = players[id] {
            return player
        }
        
        let docRef = db.collection("players").document(id)
        let document = try await docRef.getDocument()
        
        guard let player = try? document.data(as: Player.self) else {
            throw NSError(domain: "PlayerService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode player"])
        }
        
        players[id] = player
        return player
    }
    
    func updatePlayer(_ player: Player) async throws {
        guard let id = player.id else {
            throw NSError(domain: "PlayerService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Player ID is missing"])
        }
        
        try db.collection("players").document(id).setData(from: player)
        players[id] = player
    }
} 