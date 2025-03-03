import SwiftUI
import Charts

struct StatisticsDashboardView: View {
    enum TimeRange {
        case week
        case month
        case year
        case allTime
    }
    
    enum ChartType {
        case elo
        case winRate
        case matchesPlayed
    }
    
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var matchService: MatchService
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let player = authService.currentUser {
                        PlayerStatsCard(player: player)
                        RecentMatchesCard()
                        ProgressCard()
                    } else {
                        ProgressView()
                    }
                }
                .padding()
            }
            .navigationTitle("Statistics")
        }
    }
}

private struct PlayerStatsCard: View {
    let player: Player
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Player Statistics")
                .font(.headline)
                .padding(.bottom, 5)
            
            StatRow(title: "ELO Rating", value: String(format: "%.0f", player.eloRating))
            StatRow(title: "Matches Played", value: "\(player.matchesPlayed)")
            StatRow(title: "Win Rate", value: String(format: "%.1f%%", Double(player.matchesWon) / Double(max(1, player.matchesPlayed)) * 100))
            StatRow(title: "Win/Loss", value: "\(player.matchesWon)/\(player.matchesLost)")
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}

private struct RecentMatchesCard: View {
    @EnvironmentObject var matchService: MatchService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Matches")
                .font(.headline)
                .padding(.bottom, 5)
            
            if matchService.recentMatches.isEmpty {
                Text("No recent matches")
                    .foregroundColor(.gray)
            } else {
                ForEach(matchService.recentMatches) { match in
                    MatchRow(match: match)
                    if match.id != matchService.recentMatches.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}

private struct ProgressCard: View {
    @EnvironmentObject var matchService: MatchService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Progress")
                .font(.headline)
                .padding(.bottom, 5)
            
            // Add progress-related statistics here
            Text("Coming soon...")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}

private struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
        }
    }
}

private struct MatchRow: View {
    let match: Match
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(match.player1Name) vs \(match.player2Name)")
                    .font(.subheadline)
                Spacer()
                if let score1 = match.player1Score, let score2 = match.player2Score {
                    Text("\(score1) - \(score2)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(match.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let trend: Double?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            if let trend = trend {
                HStack {
                    Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text("\(abs(trend), specifier: "%.1f")%")
                        .font(.caption)
                }
                .foregroundColor(trend >= 0 ? .green : .red)
            }
        }
        .frame(width: 120)
        .padding()
        #if os(macOS)
        .background(Color(NSColor.windowBackgroundColor))
        #else
        .background(Color(UIColor.systemBackground))
        #endif
        .cornerRadius(15)
        .shadow(radius: 2)
    }
}

struct DetailedStatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

class StatisticsDashboardViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var chartData: [ChartPoint] = []
    @Published var recentAchievements: [Achievement] = []
    
    // Summary Statistics
    var currentElo = 1200
    var winRate = 0
    var averageScore = 0
    var totalMatches = 0
    
    // Trends
    var eloTrend: Double?
    var winRateTrend: Double?
    var scoreTrend: Double?
    
    // Detailed Statistics
    var highestElo = 0
    var lowestElo = 0
    var bestScore = 0
    var tournamentWinRate = 0
    var averageMatchDuration = 0
    
    @MainActor
    func loadData(timeRange: StatisticsDashboardView.TimeRange) async {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Implement actual data loading
        // For now, using sample data
        currentElo = 1250
        winRate = 65
        averageScore = 72
        totalMatches = 42
        
        eloTrend = 5.2
        winRateTrend = -2.1
        scoreTrend = 1.8
        
        highestElo = 1300
        lowestElo = 1100
        bestScore = 68
        tournamentWinRate = 70
        averageMatchDuration = 45
        
        // Sample chart data
        updateChart(type: .elo)
        
        // Sample achievements
        recentAchievements = [
            Achievement(
                title: "Win Streak",
                description: "Won 5 matches in a row",
                icon: "star.fill",
                date: Date()
            )
        ]
    }
    
    func updateChart(type: StatisticsDashboardView.ChartType) {
        // TODO: Implement actual chart data processing
        // For now, using sample data
        let dates = (-30...0).map { Calendar.current.date(byAdding: .day, value: $0, to: Date())! }
        
        switch type {
        case .elo:
            chartData = dates.map { date in
                ChartPoint(date: date, value: Double.random(in: 1100...1300))
            }
        case .winRate:
            chartData = dates.map { date in
                ChartPoint(date: date, value: Double.random(in: 0...100))
            }
        case .matchesPlayed:
            chartData = dates.map { date in
                ChartPoint(date: date, value: Double.random(in: 0...50))
            }
        }
    }
}

struct ChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let date: Date
} 