import SwiftUI

struct TournamentParticipantsView: View {
    let participants: [Player]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Participants (\(participants.count))")
                .font(.headline)
                .padding(.bottom, 5)
            
            ForEach(participants) { player in
                HStack {
                    Text(player.name)
                    Spacer()
                    Text("ELO: \(player.eloRating)")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 5)
                Divider()
            }
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
} 