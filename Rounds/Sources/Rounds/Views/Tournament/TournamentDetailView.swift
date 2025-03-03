import SwiftUI

struct TournamentDetailView: View {
    @ObservedObject var tournament: Tournament
    @StateObject private var viewModel: TournamentDetailViewModel
    @EnvironmentObject var tournamentService: TournamentService
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var playerService: PlayerService
    
    init(tournament: Tournament) {
        self.tournament = tournament
        self._viewModel = StateObject(wrappedValue: TournamentDetailViewModel(tournament: tournament))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                TournamentHeaderView(tournament: tournament)
                
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    TournamentParticipantsView(participants: viewModel.participants)
                    
                    if tournament.status == .registration {
                        if viewModel.isCreator {
                            Button("Start Tournament") {
                                Task {
                                    await viewModel.startTournament()
                                }
                            }
                            .disabled(tournament.participants.count < 2)
                        } else if viewModel.isParticipant {
                            Button("Withdraw") {
                                Task {
                                    await viewModel.withdrawFromTournament()
                                }
                            }
                        } else {
                            Button("Join Tournament") {
                                Task {
                                    await viewModel.joinTournament()
                                }
                            }
                        }
                    }
                    
                    if tournament.status == .inProgress {
                        TournamentBracketView(rounds: tournament.rounds)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(tournament.name)
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        .onAppear {
            viewModel.configure(
                tournamentService: tournamentService,
                authService: authService,
                playerService: playerService
            )
        }
        .task {
            await viewModel.loadTournamentDetails()
        }
    }
}

struct PlayerScore: View {
    let name: String
    let score: Int?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(name)
                .font(.subheadline)
            if let score = score {
                Text("\(score) points")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

@MainActor
class TournamentDetailViewModel: ObservableObject {
    @Published var participants: [Player] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingError = false
    
    private let tournament: Tournament
    private var tournamentService: TournamentService?
    private var authService: AuthenticationService?
    private var playerService: PlayerService?
    
    init(tournament: Tournament) {
        self.tournament = tournament
    }
    
    func configure(
        tournamentService: TournamentService,
        authService: AuthenticationService,
        playerService: PlayerService
    ) {
        self.tournamentService = tournamentService
        self.authService = authService
        self.playerService = playerService
    }
    
    var isCreator: Bool {
        guard let currentUser = authService?.currentUser,
              let userId = currentUser.id else { return false }
        return userId == tournament.creatorId
    }
    
    var isParticipant: Bool {
        guard let currentUser = authService?.currentUser,
              let userId = currentUser.id else { return false }
        return tournament.participants.contains(userId)
    }
    
    func loadTournamentDetails() async {
        guard let tournamentService = tournamentService,
              let playerService = playerService,
              let tournamentId = tournament.id else { return }
              
        isLoading = true
        defer { isLoading = false }
        
        do {
            let updatedTournament = try await tournamentService.getTournament(tournamentId)
            tournament.participants = updatedTournament.participants
            tournament.status = updatedTournament.status
            tournament.rounds = updatedTournament.rounds
            
            participants = try await playerService.getPlayers(ids: tournament.participants)
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    func joinTournament() async {
        guard let tournamentService = tournamentService,
              let currentUser = authService?.currentUser,
              let userId = currentUser.id,
              let tournamentId = tournament.id else {
            errorMessage = "You must be logged in to join"
            showingError = true
            return
        }
        
        do {
            try await tournamentService.joinTournament(tournamentId, playerId: userId)
            await loadTournamentDetails()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    func withdrawFromTournament() async {
        guard let tournamentService = tournamentService,
              let currentUser = authService?.currentUser,
              let userId = currentUser.id,
              let tournamentId = tournament.id else {
            errorMessage = "You must be logged in to withdraw"
            showingError = true
            return
        }
        
        do {
            try await tournamentService.withdrawFromTournament(tournamentId, userId: userId)
            await loadTournamentDetails()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    func startTournament() async {
        guard let tournamentService = tournamentService,
              let tournamentId = tournament.id else {
            errorMessage = "Unable to start tournament"
            showingError = true
            return
        }
        
        do {
            try await tournamentService.startTournament(tournamentId)
            await loadTournamentDetails()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}
