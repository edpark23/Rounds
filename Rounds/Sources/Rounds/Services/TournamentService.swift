import Foundation
import FirebaseFirestore

@MainActor
class TournamentService: ObservableObject {
    static private var _shared: TournamentService?
    static var shared: TournamentService {
        get async {
            if let service = _shared {
                return service
            }
            let service = await TournamentService()
            _shared = service
            return service
        }
    }
    
    private let db = Firestore.firestore()
    
    @Published var activeTournaments: [Tournament] = []
    @Published private(set) var userTournaments: [Tournament] = []
    
    init() async {
        print("TournamentService: Initializing...")
    }
    
    // MARK: - Tournament Management
    
    func createTournament(_ tournament: Tournament) async throws -> Tournament {
        let documentRef = db.collection("tournaments").document()
        var tournament = tournament
        tournament.id = documentRef.documentID
        try await documentRef.setData(from: tournament)
        return tournament
    }
    
    func updateTournament(_ tournament: Tournament) async throws {
        guard let id = tournament.id else { throw TournamentError.invalidTournament }
        try db.collection("tournaments").document(id).setData(from: tournament)
    }
    
    func deleteTournament(_ tournamentId: String) async throws {
        try await db.collection("tournaments").document(tournamentId).delete()
    }
    
    func getTournament(_ id: String) async throws -> Tournament {
        let snapshot = try await db.collection("tournaments").document(id).getDocument()
        guard let tournament = try? snapshot.data(as: Tournament.self) else {
            throw TournamentError.tournamentNotFound
        }
        return tournament
    }
    
    // MARK: - Tournament Queries
    
    func fetchActiveTournaments() async throws {
        let snapshot = try await db.collection("tournaments")
            .whereField("status", isEqualTo: Tournament.TournamentStatus.registration.rawValue)
            .order(by: "startDate")
            .getDocuments()
        
        activeTournaments = try snapshot.documents.compactMap { doc in
            try doc.data(as: Tournament.self)
        }
    }
    
    func getTournaments() async throws -> [Tournament] {
        let snapshot = try await db.collection("tournaments").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Tournament.self) }
    }
    
    func fetchUserTournaments(_ userId: String) async throws {
        let snapshot = try await db.collection("tournaments")
            .whereField("participants", arrayContains: userId)
            .getDocuments()
        
        userTournaments = snapshot.documents.compactMap { try? $0.data(as: Tournament.self) }
    }
    
    // MARK: - Tournament Registration
    
    func joinTournament(_ tournamentId: String, playerId: String) async throws {
        let tournamentRef = db.collection("tournaments").document(tournamentId)
        
        let result = try await db.runTransaction { transaction, errorPointer in
            do {
                let snapshot = try transaction.getDocument(tournamentRef)
                guard var tournament = try? snapshot.data(as: Tournament.self) else {
                    throw TournamentError.tournamentNotFound
                }
                
                guard tournament.status == .registration else {
                    throw TournamentError.registrationClosed
                }
                
                guard !tournament.participants.contains(playerId) else {
                    throw TournamentError.alreadyRegistered
                }
                
                guard tournament.participants.count < tournament.maxPlayers else {
                    throw TournamentError.tournamentFull
                }
                
                tournament.participants.append(playerId)
                tournament.updatedAt = Date()
                
                try transaction.setData(from: tournament, forDocument: tournamentRef)
                return tournament
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        
        guard result != nil else {
            throw TournamentError.invalidTournament
        }
    }
    
    func withdrawFromTournament(_ tournamentId: String, userId: String) async throws {
        let tournamentRef = db.collection("tournaments").document(tournamentId)
        
        let result = try await db.runTransaction { transaction, errorPointer in
            do {
                let snapshot = try transaction.getDocument(tournamentRef)
                guard var tournament = try? snapshot.data(as: Tournament.self) else {
                    throw TournamentError.tournamentNotFound
                }
                
                guard tournament.status == .registration else {
                    throw TournamentError.tournamentStarted
                }
                
                guard tournament.participants.contains(userId) else {
                    throw TournamentError.tournamentNotFound
                }
                
                tournament.participants.removeAll { $0 == userId }
                tournament.updatedAt = Date()
                
                try transaction.setData(from: tournament, forDocument: tournamentRef)
                return tournament
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        
        guard result != nil else {
            throw TournamentError.invalidTournament
        }
    }
    
    // MARK: - Tournament Progress
    
    func startTournament(_ tournamentId: String) async throws {
        let tournamentRef = db.collection("tournaments").document(tournamentId)
        
        let result = try await db.runTransaction { transaction, errorPointer in
            do {
                let snapshot = try transaction.getDocument(tournamentRef)
                guard var tournament = try? snapshot.data(as: Tournament.self) else {
                    throw TournamentError.tournamentNotFound
                }
                
                guard tournament.participants.count >= tournament.minPlayers else {
                    throw TournamentError.notEnoughPlayers
                }
                
                tournament.status = .inProgress
                tournament.rounds = Tournament.generateBracket(
                    players: tournament.participants,
                    format: tournament.format
                )
                tournament.updatedAt = Date()
                
                try transaction.setData(from: tournament, forDocument: tournamentRef)
                return tournament
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        
        guard result != nil else {
            throw TournamentError.invalidTournament
        }
    }
    
    func submitMatchResult(
        tournamentId: String,
        roundId: String,
        matchId: String,
        player1Score: Int,
        player2Score: Int
    ) async throws {
        let tournamentRef = db.collection("tournaments").document(tournamentId)
        
        let result = try await db.runTransaction { transaction, errorPointer in
            do {
                let snapshot = try transaction.getDocument(tournamentRef)
                guard var tournament = try? snapshot.data(as: Tournament.self) else {
                    throw NSError(domain: "TournamentService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Tournament not found"])
                }
                
                guard let roundIndex = tournament.rounds.firstIndex(where: { $0.id == roundId }),
                      let matchIndex = tournament.rounds[roundIndex].matches.firstIndex(where: { $0.id == matchId })
                else {
                    throw TournamentError.matchNotFound
                }
                
                // Update match result
                tournament.rounds[roundIndex].matches[matchIndex].player1Score = player1Score
                tournament.rounds[roundIndex].matches[matchIndex].player2Score = player2Score
                tournament.rounds[roundIndex].matches[matchIndex].winner = player1Score > player2Score
                    ? tournament.rounds[roundIndex].matches[matchIndex].player1Id
                    : tournament.rounds[roundIndex].matches[matchIndex].player2Id
                tournament.rounds[roundIndex].matches[matchIndex].status = .completed
                tournament.rounds[roundIndex].matches[matchIndex].completedTime = Date()
                
                // Check if round is completed
                if tournament.rounds[roundIndex].matches.allSatisfy({ $0.status == .completed }) {
                    tournament.rounds[roundIndex].status = .completed
                }
                
                // Check if tournament is completed
                if tournament.rounds.allSatisfy({ $0.status == .completed }) {
                    tournament.status = .completed
                }
                
                tournament.updatedAt = Date()
                try transaction.setData(from: tournament, forDocument: tournamentRef)
                return tournament
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        
        guard result != nil else {
            throw TournamentError.invalidTournament
        }
    }
    
    private func updateNextRoundMatches(_ nextRound: inout TournamentRound, with currentMatches: [TournamentMatch]) {
        var winners: [String] = []
        for match in currentMatches {
            if let winner = match.winner {
                winners.append(winner)
            }
        }
        
        for i in 0..<nextRound.matches.count {
            if i * 2 < winners.count {
                nextRound.matches[i].player1Id = winners[i * 2]
            }
            if i * 2 + 1 < winners.count {
                nextRound.matches[i].player2Id = winners[i * 2 + 1]
            }
        }
    }
}

enum TournamentError: LocalizedError {
    case invalidTournament
    case tournamentNotFound
    case tournamentFull
    case registrationClosed
    case alreadyRegistered
    case tournamentStarted
    case notEnoughPlayers
    case matchNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidTournament:
            return "Invalid tournament data"
        case .tournamentNotFound:
            return "Tournament not found"
        case .tournamentFull:
            return "Tournament is full"
        case .registrationClosed:
            return "Tournament registration is closed"
        case .alreadyRegistered:
            return "You are already registered for this tournament"
        case .tournamentStarted:
            return "Tournament has already started"
        case .notEnoughPlayers:
            return "Not enough players to start the tournament"
        case .matchNotFound:
            return "Match not found"
        }
    }
} 