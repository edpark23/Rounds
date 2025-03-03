import SwiftUI
import FirebaseFirestore

struct MatchSubmissionView: View {
    let course: GolfCourse
    let tee: GolfCourse.Scorecard.Tee
    let opponent: Player
    @StateObject private var matchService: MatchService
    @EnvironmentObject private var authService: AuthenticationService
    @Environment(\.dismiss) private var dismiss
    @State private var score1 = ""
    @State private var score2 = ""
    @State private var errorMessage = ""
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Your Score", text: $score1)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.numberPad)
                    TextField("Opponent's Score", text: $score2)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.numberPad)
                }
                
                Button("Submit Scores") {
                    submitScores()
                }
                .disabled(score1.isEmpty || score2.isEmpty)
            }
            .navigationTitle("Submit Scores")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    init(course: GolfCourse, tee: GolfCourse.Scorecard.Tee, opponent: Player, matchService: MatchService? = nil) {
        self.course = course
        self.tee = tee
        self.opponent = opponent
        self._matchService = StateObject(wrappedValue: matchService ?? MatchService(authService: AuthenticationService.shared))
    }
    
    private func submitScores() {
        guard let score1Int = Int(score1), let score2Int = Int(score2) else {
            errorMessage = "Please enter valid scores"
            showingError = true
            return
        }
        
        Task {
            do {
                let match = try await matchService.createMatch(
                    player1: authService.currentPlayer!,
                    player2: opponent,
                    course: course,
                    tee: tee
                )
                
                try await matchService.submitScores(
                    matchId: match.id,
                    player1Score: score1Int,
                    player2Score: score2Int
                )
                
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

@MainActor
class MatchSubmissionViewModel: ObservableObject {
    @Published var currentPlayerScore = ""
    @Published var opponentScore = ""
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var isLoading = false
    
    let currentPlayer: Player
    let opponent: Player
    let course: GolfCourse
    @StateObject private var matchService: MatchService
    
    init(currentPlayer: Player, opponent: Player, course: GolfCourse, matchService: MatchService? = nil) {
        self.currentPlayer = currentPlayer
        self.opponent = opponent
        self.course = course
        _matchService = StateObject(wrappedValue: matchService ?? MatchService())
    }
    
    var isValid: Bool {
        guard let score1 = Int(currentPlayerScore),
              let score2 = Int(opponentScore),
              score1 >= 0,
              score2 >= 0
        else { return false }
        return true
    }
    
    func submitMatch() async throws {
        guard isValid else {
            errorMessage = "Please enter valid scores"
            showError = true
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let match = try await matchService.createMatch(
                player1: currentPlayer,
                player2: opponent,
                course: course
            )
            
            try await matchService.submitScores(
                match: match,
                player1Score: Int(currentPlayerScore)!,
                player2Score: Int(opponentScore)!
            )
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            throw error
        }
    }
} 