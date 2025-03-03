import SwiftUI

struct MatchSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var matchService: MatchService
    @EnvironmentObject private var playerService: PlayerService
    @State private var opponentEmail = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let course: GolfCourse
    let tee: GolfCourse.Scorecard.Tee
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text(course.name)
                        .font(.headline)
                    Text("Selected Tee: \(tee.name)")
                        .font(.subheadline)
                    Text("Rating: \(String(format: "%.1f", tee.rating)) / Slope: \(tee.slope)")
                        .font(.caption)
                }
                
                Section("Opponent") {
                    TextField("Opponent's Email", text: $opponentEmail)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }
                
                Button("Start Match") {
                    startMatch()
                }
                .disabled(opponentEmail.isEmpty)
            }
            .navigationTitle("Match Setup")
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
    
    private func startMatch() {
        Task {
            do {
                let opponent = try await playerService.findPlayerByEmail(opponentEmail)
                try await matchService.startMatch(opponent: opponent, course: course, tee: tee)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
} 