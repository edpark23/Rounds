import SwiftUI

struct TournamentBracketView: View {
    let rounds: [TournamentRound]
    @EnvironmentObject private var playerService: PlayerService
    @State private var players: [String: Player] = [:]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Tournament Bracket")
                .font(.headline)
                .padding(.bottom, 5)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 20) {
                    ForEach(rounds) { round in
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Round \(round.roundNumber)")
                                .font(.subheadline)
                                .bold()
                            
                            VStack(spacing: 20) {
                                ForEach(round.matches) { match in
                                    MatchView(match: match, players: players)
                                }
                            }
                        }
                        .frame(width: 200)
                        
                        if round.roundNumber < rounds.count {
                            Divider()
                        }
                    }
                }
                .padding()
            }
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(10)
        .shadow(radius: 1)
        .task {
            await loadPlayers()
        }
    }
    
    private func loadPlayers() async {
        let playerIds = Set(rounds.flatMap { $0.matches }.flatMap { [$0.player1Id, $0.player2Id] }.filter { !$0.isEmpty })
        do {
            let fetchedPlayers = try await playerService.getPlayers(ids: Array(playerIds))
            players = Dictionary(uniqueKeysWithValues: fetchedPlayers.map { ($0.id!, $0) })
        } catch {
            print("Error loading players: \(error)")
        }
    }
}

private struct MatchView: View {
    let match: TournamentMatch
    let players: [String: Player]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !match.player1Id.isEmpty {
                Text(players[match.player1Id]?.name ?? "Unknown Player")
                    .fontWeight(match.winner == match.player1Id ? .bold : .regular)
            } else {
                Text("TBD")
                    .foregroundColor(.gray)
            }
            
            Text("vs")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !match.player2Id.isEmpty {
                Text(players[match.player2Id]?.name ?? "Unknown Player")
                    .fontWeight(match.winner == match.player2Id ? .bold : .regular)
            } else {
                Text("TBD")
                    .foregroundColor(.gray)
            }
            
            if match.status == .completed {
                HStack {
                    Text("\(match.player1Score ?? 0)")
                    Text("-")
                    Text("\(match.player2Score ?? 0)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(nsColor: .underPageBackgroundColor))
        .cornerRadius(8)
    }
} 