import Foundation
import FirebaseFirestore

class Tournament: ObservableObject, Codable, Identifiable {
    var id: String?
    @Published var name: String
    @Published var description: String
    @Published var startDate: Date
    @Published var endDate: Date
    @Published var venue: String
    @Published var location: String
    @Published var par: Int
    @Published var yardage: Int
    @Published var purse: Double
    @Published var timeZone: String
    @Published var format: TournamentFormat
    @Published var status: TournamentStatus
    @Published var participants: [String]
    @Published var rounds: [TournamentRound]
    @Published var creatorId: String
    @Published var minPlayers: Int
    @Published var maxPlayers: Int
    @Published var entryFee: Int?
    @Published var prizePool: Double?
    @Published var rules: [String]
    @Published var createdAt: Date
    @Published var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case startDate
        case endDate
        case venue
        case location
        case par
        case yardage
        case purse
        case timeZone
        case format
        case status
        case participants
        case rounds
        case creatorId
        case minPlayers
        case maxPlayers
        case entryFee
        case prizePool
        case rules
        case createdAt
        case updatedAt
    }
    
    init(
        id: String? = nil,
        name: String,
        description: String,
        startDate: Date,
        endDate: Date,
        venue: String,
        location: String,
        par: Int,
        yardage: Int,
        purse: Double,
        timeZone: String,
        format: TournamentFormat,
        status: TournamentStatus,
        participants: [String],
        rounds: [TournamentRound],
        creatorId: String,
        minPlayers: Int,
        maxPlayers: Int,
        entryFee: Int?,
        prizePool: Double?,
        rules: [String],
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.venue = venue
        self.location = location
        self.par = par
        self.yardage = yardage
        self.purse = purse
        self.timeZone = timeZone
        self.format = format
        self.status = status
        self.participants = participants
        self.rounds = rounds
        self.creatorId = creatorId
        self.minPlayers = minPlayers
        self.maxPlayers = maxPlayers
        self.entryFee = entryFee
        self.prizePool = prizePool
        self.rules = rules
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decode(Date.self, forKey: .endDate)
        venue = try container.decode(String.self, forKey: .venue)
        location = try container.decode(String.self, forKey: .location)
        par = try container.decode(Int.self, forKey: .par)
        yardage = try container.decode(Int.self, forKey: .yardage)
        purse = try container.decode(Double.self, forKey: .purse)
        timeZone = try container.decode(String.self, forKey: .timeZone)
        format = try container.decode(TournamentFormat.self, forKey: .format)
        status = try container.decode(TournamentStatus.self, forKey: .status)
        participants = try container.decode([String].self, forKey: .participants)
        rounds = try container.decode([TournamentRound].self, forKey: .rounds)
        creatorId = try container.decode(String.self, forKey: .creatorId)
        minPlayers = try container.decode(Int.self, forKey: .minPlayers)
        maxPlayers = try container.decode(Int.self, forKey: .maxPlayers)
        entryFee = try container.decodeIfPresent(Int.self, forKey: .entryFee)
        prizePool = try container.decodeIfPresent(Double.self, forKey: .prizePool)
        rules = try container.decode([String].self, forKey: .rules)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(venue, forKey: .venue)
        try container.encode(location, forKey: .location)
        try container.encode(par, forKey: .par)
        try container.encode(yardage, forKey: .yardage)
        try container.encode(purse, forKey: .purse)
        try container.encode(timeZone, forKey: .timeZone)
        try container.encode(format, forKey: .format)
        try container.encode(status, forKey: .status)
        try container.encode(participants, forKey: .participants)
        try container.encode(rounds, forKey: .rounds)
        try container.encode(creatorId, forKey: .creatorId)
        try container.encode(minPlayers, forKey: .minPlayers)
        try container.encode(maxPlayers, forKey: .maxPlayers)
        try container.encodeIfPresent(entryFee, forKey: .entryFee)
        try container.encodeIfPresent(prizePool, forKey: .prizePool)
        try container.encode(rules, forKey: .rules)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    enum TournamentFormat: String, Codable {
        case stroke = "Stroke"
        case match = "Match"
        case team = "Team"
        case singleElimination = "SingleElimination"
        case doubleElimination = "DoubleElimination"
        case roundRobin = "RoundRobin"
        case swiss = "Swiss"
        case unknown = "Unknown"
    }
    
    enum TournamentStatus: String, Codable {
        case registration = "registration"
        case inProgress = "in_progress"
        case completed = "completed"
        case cancelled = "cancelled"
    }
}

// MARK: - SportsData.io Tournament Model
struct SDTournament: Codable {
    let TournamentID: Int
    let Name: String
    let StartDate: String
    let EndDate: String
    let IsOver: Bool?
    let IsInProgress: Bool?
    let Venue: String?
    let Location: String?
    let Par: Int?
    let Yards: Int?
    let Purse: Double?
    let StartDateTime: String?
    let Canceled: Bool?
    let Covered: Bool?
    let City: String?
    let State: String?
    let ZipCode: String?
    let Country: String?
    let TimeZone: String?
    let Format: String?
    let SportRadarTournamentID: String?
    let OddsCoverage: String?
    let Rounds: [Round]
    
    func toTournament() -> Tournament {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        return Tournament(
            id: nil,
            name: Name,
            description: "",
            startDate: dateFormatter.date(from: StartDate) ?? Date(),
            endDate: dateFormatter.date(from: EndDate) ?? Date(),
            venue: Venue ?? "",
            location: Location ?? "",
            par: Par ?? 0,
            yardage: Yards ?? 0,
            purse: Purse ?? 0,
            timeZone: TimeZone ?? "",
            format: Tournament.TournamentFormat(rawValue: Format ?? "") ?? .unknown,
            status: .registration,
            participants: [],
            rounds: [],
            creatorId: "",
            minPlayers: 0,
            maxPlayers: 0,
            entryFee: nil,
            prizePool: nil,
            rules: [],
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

struct Round: Codable {
    let TournamentID: Int
    let RoundID: Int
    let Number: Int
    let Day: String
}

struct TournamentRound: Codable, Identifiable {
    var id: String
    var roundNumber: Int
    var matches: [TournamentMatch]
    var status: RoundStatus
    
    enum RoundStatus: String, Codable {
        case pending
        case inProgress
        case completed
        case cancelled
    }
    
    static func create(
        id: String = UUID().uuidString,
        roundNumber: Int,
        matches: [TournamentMatch],
        status: RoundStatus = .pending
    ) -> TournamentRound {
        TournamentRound(
            id: id,
            roundNumber: roundNumber,
            matches: matches,
            status: status
        )
    }
}

enum MatchStatus: String, Codable {
    case pending
    case inProgress
    case completed
    case cancelled
}

struct TournamentMatch: Codable, Identifiable {
    var id: String
    var player1Id: String
    var player2Id: String
    var player1Score: Int?
    var player2Score: Int?
    var winner: String?
    var matchNumber: Int
    var status: MatchStatus
    var completedTime: Date?
    
    init(id: String = UUID().uuidString,
         player1Id: String,
         player2Id: String,
         player1Score: Int? = nil,
         player2Score: Int? = nil,
         winner: String? = nil,
         matchNumber: Int,
         status: MatchStatus = .pending,
         completedTime: Date? = nil) {
        self.id = id
        self.player1Id = player1Id
        self.player2Id = player2Id
        self.player1Score = player1Score
        self.player2Score = player2Score
        self.winner = winner
        self.matchNumber = matchNumber
        self.status = status
        self.completedTime = completedTime
    }
}

extension Tournament {
    static func generateBracket(players: [String], format: TournamentFormat) -> [TournamentRound] {
        var rounds: [TournamentRound] = []
        var remainingPlayers = players
        var matchNumber = 1
        
        switch format {
        case .singleElimination:
            while !remainingPlayers.isEmpty {
                var matches: [TournamentMatch] = []
                while remainingPlayers.count >= 2 {
                    let match = TournamentMatch(
                        id: UUID().uuidString,
                        player1Id: remainingPlayers.removeFirst(),
                        player2Id: remainingPlayers.removeFirst(),
                        matchNumber: matchNumber,
                        status: .pending
                    )
                    matches.append(match)
                    matchNumber += 1
                }
                
                // If there's an odd player out, create a match with an empty opponent
                if !remainingPlayers.isEmpty {
                    let match = TournamentMatch(
                        id: UUID().uuidString,
                        player1Id: remainingPlayers.removeFirst(),
                        player2Id: "", // Empty opponent
                        matchNumber: matchNumber,
                        status: .pending
                    )
                    matches.append(match)
                    matchNumber += 1
                }
                
                rounds.append(TournamentRound(
                    id: UUID().uuidString,
                    roundNumber: rounds.count + 1,
                    matches: matches,
                    status: .pending
                ))
            }
            
        case .doubleElimination, .roundRobin, .swiss:
            // Placeholder for other tournament formats
            let match = TournamentMatch(
                id: UUID().uuidString,
                player1Id: "",
                player2Id: "",
                matchNumber: matchNumber,
                status: .pending
            )
            rounds.append(TournamentRound(
                id: UUID().uuidString,
                roundNumber: 1,
                matches: [match],
                status: .pending
            ))
        case .stroke:
            let round = TournamentRound(
                id: UUID().uuidString,
                roundNumber: 1,
                matches: [
                    TournamentMatch(
                        id: UUID().uuidString,
                        player1Id: players.first ?? "",
                        player2Id: players.last ?? "",
                        player1Score: nil,
                        player2Score: nil,
                        matchNumber: 1,
                        status: .pending
                    )
                ],
                status: .pending
            )
            return [round]
        case .match:
            return generateSingleEliminationBracket(players: players)
        case .team:
            let round = TournamentRound(
                id: UUID().uuidString,
                roundNumber: 1,
                matches: [
                    TournamentMatch(
                        id: UUID().uuidString,
                        player1Id: players.first ?? "",
                        player2Id: players.last ?? "",
                        player1Score: nil,
                        player2Score: nil,
                        matchNumber: 1,
                        status: .pending
                    )
                ],
                status: .pending
            )
            return [round]
        case .unknown:
            return []
        }
        
        return rounds
    }
    
    private static func generateSingleEliminationBracket(players: [String]) -> [TournamentRound] {
        var rounds: [TournamentRound] = []
        var matchNumber = 1
        
        // Calculate number of rounds needed
        let numPlayers = players.count
        let numRounds = Int(ceil(log2(Double(numPlayers))))
        
        // Generate first round matches
        var firstRoundMatches: [TournamentMatch] = []
        var remainingPlayers = players
        
        // Add byes if necessary
        let totalSlots = Int(pow(2.0, Double(numRounds)))
        let numByes = totalSlots - numPlayers
        
        for i in 0..<(numPlayers/2 + numByes) {
            let match = TournamentMatch(
                id: UUID().uuidString,
                player1Id: remainingPlayers.isEmpty ? "" : remainingPlayers.removeFirst(),
                player2Id: remainingPlayers.isEmpty ? "" : remainingPlayers.removeFirst(),
                player1Score: nil,
                player2Score: nil,
                winner: nil,
                matchNumber: matchNumber,
                status: .pending,
                completedTime: nil
            )
            firstRoundMatches.append(match)
            matchNumber += 1
        }
        
        rounds.append(TournamentRound(
            id: UUID().uuidString,
            roundNumber: 1,
            matches: firstRoundMatches,
            status: .pending
        ))
        
        // Generate subsequent rounds
        for roundNum in 2...numRounds {
            let numMatches = Int(pow(2.0, Double(numRounds - roundNum)))
            var matches: [TournamentMatch] = []
            
            for _ in 0..<numMatches {
                let match = TournamentMatch(
                    id: UUID().uuidString,
                    player1Id: "",
                    player2Id: "",
                    player1Score: nil,
                    player2Score: nil,
                    winner: nil,
                    matchNumber: matchNumber,
                    status: .pending,
                    completedTime: nil
                )
                matches.append(match)
                matchNumber += 1
            }
            
            rounds.append(TournamentRound(
                id: UUID().uuidString,
                roundNumber: roundNum,
                matches: matches,
                status: .pending
            ))
        }
        
        return rounds
    }
    
    private static func generateDoubleEliminationBracket(players: [String]) -> [TournamentRound] {
        // TODO: Implement double elimination bracket generation
        return []
    }
    
    private static func generateRoundRobinBracket(players: [String]) -> [TournamentRound] {
        var rounds: [TournamentRound] = []
        var matchNumber = 1
        
        // For n players, we need (n-1) rounds
        let numRounds = players.count - 1
        
        for roundNum in 1...numRounds {
            var matches: [TournamentMatch] = []
            var roundPlayers = players
            
            while roundPlayers.count >= 2 {
                let player1 = roundPlayers.removeFirst()
                let player2 = roundPlayers.removeLast()
                
                let match = TournamentMatch(
                    id: UUID().uuidString,
                    player1Id: player1,
                    player2Id: player2,
                    matchNumber: matchNumber,
                    status: .pending
                )
                matches.append(match)
                matchNumber += 1
            }
            
            rounds.append(TournamentRound(
                id: UUID().uuidString,
                roundNumber: roundNum,
                matches: matches,
                status: .pending
            ))
        }
        
        return rounds
    }
    
    private static func generateSwissBracket(players: [String]) -> [TournamentRound] {
        // TODO: Implement Swiss system bracket generation
        return []
    }
} 