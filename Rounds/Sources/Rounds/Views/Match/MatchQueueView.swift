import SwiftUI

struct MatchQueueView: View {
    @EnvironmentObject private var matchService: MatchService
    @State private var showingCreateMatch = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            List {
                if let currentMatch = matchService.currentMatch {
                    Section("Current Match") {
                        NavigationLink(destination: MatchDetailView(match: currentMatch)) {
                            MatchQueueRow(match: currentMatch)
                        }
                    }
                }
                
                Section("Queued Matches") {
                    if matchService.matchQueue.isEmpty {
                        Text("No matches in queue")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(matchService.matchQueue) { match in
                            MatchQueueRow(match: match)
                        }
                    }
                }
            }
            .navigationTitle("Match Queue")
            .refreshable {
                await matchService.loadMatchQueue()
            }
            .toolbar {
                Button(action: { showingCreateMatch = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingCreateMatch) {
                CourseSelectionView()
            }
        }
        .task {
            await matchService.loadMatchQueue()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

struct MatchQueueRow: View {
    let match: Match
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(match.courseName)
                .font(.headline)
            HStack {
                Text("\(match.player1Name) vs \(match.player2Name)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(match.selectedTee)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
} 