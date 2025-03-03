struct Tournament: Codable {
    let TournamentID: Int
    let Name: String
    let StartDate: String
    let EndDate: String
    let IsOver: Bool
    let IsInProgress: Bool
    let Venue: String?
    let Location: String?
    let Par: Int?
    let Yards: Int?
    let Purse: Double?
    let StartDateTime: String?
    let Canceled: Bool
    let Covered: Bool
    let City: String?
    let State: String?
    let ZipCode: String?
    let Country: String?
    let TimeZone: String?
    let Format: String?
    let SportRadarTournamentID: String?
    let OddsCoverage: String?
    let Rounds: [Round]
}

struct Round: Codable {
    let TournamentID: Int
    let RoundID: Int
    let Number: Int
    let Day: String
} 