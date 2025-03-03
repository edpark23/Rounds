import SwiftUI

struct MatchmakingView: View {
    @StateObject private var matchmakingService = MatchmakingService()
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var showingCancelAlert = false
    @State private var showingMatchFoundAlert = false
    @State private var timeInQueue = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 20) {
            if matchmakingService.isSearching {
                // Searching state
                VStack(spacing: 30) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("Searching for opponent...")
                        .font(.title2)
                    
                    Text("Time in queue: \(timeString(from: timeInQueue))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("ELO Rating: \(Int(authService.currentUser?.eloRating ?? 0))")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    
                    RoundsButton("Cancel", isLoading: false) {
                        showingCancelAlert = true
                    }
                }
                .onReceive(timer) { _ in
                    timeInQueue += 1
                }
            } else {
                // Initial state
                VStack(spacing: 30) {
                    Image(systemName: "figure.golf")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                    
                    Text("Ready to Play?")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("You'll be matched with a player of similar skill level")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                    if let player = authService.currentUser {
                        RoundsButton("Start Matchmaking", isLoading: false) {
                            Task {
                                try? await matchmakingService.startMatchmaking(for: player)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .alert("Cancel Matchmaking?", isPresented: $showingCancelAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Yes", role: .destructive) {
                Task {
                    if let playerId = authService.currentUser?.id {
                        try? await matchmakingService.cancelMatchmaking(for: playerId)
                        timeInQueue = 0
                    }
                }
            }
        } message: {
            Text("Are you sure you want to cancel matchmaking?")
        }
        .alert("Match Found!", isPresented: $showingMatchFoundAlert) {
            Button("Accept", role: .none) {
                if let match = matchmakingService.matchFound {
                    Task {
                        try? await matchmakingService.acceptMatch(match: match)
                    }
                }
            }
            Button("Decline", role: .destructive) {
                if let playerId = authService.currentUser?.id {
                    Task {
                        try? await matchmakingService.cancelMatchmaking(for: playerId)
                        timeInQueue = 0
                    }
                }
            }
        } message: {
            if let queue = matchmakingService.currentQueue {
                Text("Found opponent: \(queue.playerName)")
            }
        }
        .onChange(of: matchmakingService.matchFound) { match in
            if match != nil {
                showingMatchFoundAlert = true
            }
        }
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

#Preview {
    MatchmakingView()
        .environmentObject(AuthenticationService())
} 