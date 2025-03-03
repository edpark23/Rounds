import SwiftUI

struct TournamentHeaderView: View {
    let tournament: Tournament
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(tournament.name)
                    .font(.title)
                    .bold()
                Spacer()
                StatusBadge(status: tournament.status)
            }
            
            Text(tournament.description)
                .foregroundColor(.secondary)
            
            HStack {
                Label("\(tournament.participants.count) participants", systemImage: "person.3")
                Spacer()
                Text("Created \(tournament.createdAt.formatted())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}

private struct StatusBadge: View {
    let status: Tournament.TournamentStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .foregroundColor(.white)
            .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch status {
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