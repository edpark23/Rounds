import SwiftUI

struct LeaderboardView: View {
    @StateObject private var leaderboardService = LeaderboardService()
    @State private var searchText = ""
    @State private var showingSearchResults = false
    @State private var searchResults: [Player] = []
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if leaderboardService.isLoading {
                    ProgressView("Loading leaderboard...")
                } else if !leaderboardService.players.isEmpty {
                    List {
                        ForEach(Array(leaderboardService.players.enumerated()), id: \.element.id) { index, player in
                            LeaderboardRowView(rank: index + 1, player: player)
                        }
                    }
                    .refreshable {
                        leaderboardService.startListening()
                    }
                } else if let error = leaderboardService.error {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text(error)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("Try Again") {
                            leaderboardService.startListening()
                        }
                    }
                } else {
                    Text("No players found")
                }
            }
            .navigationTitle("Leaderboard")
            .searchable(text: $searchText, prompt: "Search players")
            .onChange(of: searchText) { newValue in
                if newValue.isEmpty {
                    showingSearchResults = false
                    searchResults = []
                }
            }
            .onSubmit(of: .search) {
                Task {
                    isSearching = true
                    do {
                        searchResults = try await leaderboardService.searchPlayers(query: searchText)
                        showingSearchResults = true
                    } catch {
                        print("Search error: \(error.localizedDescription)")
                    }
                    isSearching = false
                }
            }
            .sheet(isPresented: $showingSearchResults) {
                NavigationView {
                    List {
                        if isSearching {
                            ProgressView("Searching...")
                        } else if searchResults.isEmpty {
                            Text("No players found")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(searchResults) { player in
                                LeaderboardRowView(player: player)
                            }
                        }
                    }
                    .navigationTitle("Search Results")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingSearchResults = false
                            }
                        }
                    }
                }
            }
        }
    }
}

struct LeaderboardRowView: View {
    var rank: Int?
    let player: Player
    
    var body: some View {
        HStack {
            if let rank = rank {
                Text("#\(rank)")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .frame(width: 50, alignment: .leading)
            }
            
            VStack(alignment: .leading) {
                Text(player.name)
                    .font(.headline)
                Text(player.email)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(String(format: "%.0f", player.eloRating))
                    .font(.headline)
                    .foregroundColor(.blue)
                Text("\(player.matchesWon)/\(player.matchesLost)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
} 