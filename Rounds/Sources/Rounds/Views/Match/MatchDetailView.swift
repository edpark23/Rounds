import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import FirebaseFirestore

@available(macOS 13.0, *)
struct MatchDetailView: View {
    let match: Match
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Course")
                        .font(.headline)
                    Spacer()
                    Text(match.courseName)
                }
                HStack {
                    Text("Tee")
                        .font(.headline)
                    Spacer()
                    Text(match.selectedTee)
                }
                HStack {
                    Text("Rating/Slope")
                        .font(.headline)
                    Spacer()
                    Text("\(String(format: "%.1f", match.courseRating)) / \(match.courseSlope)")
                }
            } header: {
                Text("Course Details")
            }
            
            Section {
                HStack {
                    Text(match.player1Name)
                        .font(.headline)
                    Spacer()
                    if let score = match.player1Score {
                        Text("\(score)")
                    }
                }
                HStack {
                    Text(match.player2Name)
                        .font(.headline)
                    Spacer()
                    if let score = match.player2Score {
                        Text("\(score)")
                    }
                }
            } header: {
                Text("Players")
            }
            
            if match.isComplete {
                Section {
                    HStack {
                        Text("Winner")
                            .font(.headline)
                        Spacer()
                        if let winner = match.winner {
                            Text(winner)
                        }
                    }
                    if let eloChange = match.eloChange {
                        HStack {
                            Text("ELO Change")
                                .font(.headline)
                            Spacer()
                            Text("\(eloChange > 0 ? "+" : "")\(eloChange)")
                        }
                    }
                } header: {
                    Text("Results")
                }
            }
        }
        .navigationTitle("Match Details")
    }
}

struct MatchDetailViewFallback: View {
    let match: Match
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Course")
                    Spacer()
                    Text(match.courseName)
                }
                HStack {
                    Text("Par")
                    Spacer()
                    Text("\(match.selectedTee.par)")
                }
                HStack {
                    Text("Rating")
                    Spacer()
                    Text(String(format: "%.1f", match.selectedTee.rating))
                }
                HStack {
                    Text("Slope")
                    Spacer()
                    Text("\(match.selectedTee.slope)")
                }
            } header: {
                Text("Course Details")
            }
            
            Section {
                HStack {
                    Text("Player 1")
                    Spacer()
                    Text(match.player1Name)
                }
                HStack {
                    Text("Player 2")
                    Spacer()
                    Text(match.player2Name)
                }
                if let winner = match.winner {
                    HStack {
                        Text("Winner")
                        Spacer()
                        Text(winner)
                    }
                }
                if let player1Score = match.player1Score {
                    HStack {
                        Text("Player 1 Score")
                        Spacer()
                        Text("\(player1Score)")
                    }
                }
                if let player2Score = match.player2Score {
                    HStack {
                        Text("Player 2 Score")
                        Spacer()
                        Text("\(player2Score)")
                    }
                }
            } header: {
                Text("Match Details")
            }
        }
        .navigationTitle("Match Details")
    }
}

struct MatchDetailViewContainer: View {
    let match: Match
    
    var body: some View {
        if #available(macOS 13.0, *) {
            MatchDetailView(match: match)
        } else {
            MatchDetailViewFallback(match: match)
        }
    }
}

struct StatisticRow: View {
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
    }
} 