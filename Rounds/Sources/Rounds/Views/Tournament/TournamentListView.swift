import SwiftUI

struct TournamentListView: View {
    @EnvironmentObject var tournamentService: TournamentService
    @EnvironmentObject var authService: AuthenticationService
    @State private var tournaments: [Tournament] = []
    @State private var userTournaments: [Tournament] = []
    @State private var showingCreateTournament = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            List {
                if !userTournaments.isEmpty {
                    Section("My Tournaments") {
                        ForEach(userTournaments) { tournament in
                            NavigationLink(destination: TournamentDetailView(tournament: tournament)) {
                                TournamentRow(tournament: tournament)
                            }
                        }
                    }
                }
                
                Section("All Tournaments") {
                    ForEach(tournaments) { tournament in
                        NavigationLink(destination: TournamentDetailView(tournament: tournament)) {
                            TournamentRow(tournament: tournament)
                        }
                    }
                }
            }
            .navigationTitle("Tournaments")
            .toolbar {
                Button(action: { showingCreateTournament = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingCreateTournament) {
                CreateTournamentView()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
            .task {
                await loadTournaments()
            }
        }
    }
    
    private func loadTournaments() async {
        do {
            tournaments = try await tournamentService.getTournaments()
            
            if let userId = authService.currentUser?.id {
                try await tournamentService.fetchUserTournaments(userId)
                userTournaments = tournamentService.userTournaments
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

struct TournamentRow: View {
    let tournament: Tournament
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(tournament.name)
                .font(.headline)
            HStack {
                Label("\(tournament.participants.count) participants", systemImage: "person.3")
                    .font(.caption)
                Spacer()
                Text(tournament.status.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(8)
            }
        }
    }
    
    private var statusColor: Color {
        switch tournament.status {
        case .registration:
            return .orange
        case .inProgress:
            return .blue
        case .completed:
            return .green
        case .cancelled:
            return .red
        }
    }
} 