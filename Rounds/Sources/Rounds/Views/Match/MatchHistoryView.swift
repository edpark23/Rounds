import SwiftUI
import FirebaseFirestore

@available(macOS 13.0, *)
struct MatchHistoryView: View {
    @StateObject private var viewModel = MatchHistoryViewModel()
    @EnvironmentObject private var authService: AuthenticationService
    @State private var selectedFilter: MatchFilter = .all
    @State private var showingDatePicker = false
    @State private var selectedStartDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var selectedEndDate = Date()
    
    enum MatchFilter {
        case all, wins, losses, tournaments
    }
    
    var body: some View {
        NavigationView {
            List {
                // Quick Stats Section
                Section(header: Text("Quick Stats")) {
                    HStack {
                        StatBox(title: "Matches", value: "\(viewModel.totalMatches)")
                        StatBox(title: "Win Rate", value: "\(winRate)%")
                        StatBox(title: "Avg Score", value: "\(averageScore)")
                    }
                }
                
                // Filters Section
                Section {
                    Picker("Filter", selection: $selectedFilter) {
                        Text("All").tag(MatchFilter.all)
                        Text("Wins").tag(MatchFilter.wins)
                        Text("Losses").tag(MatchFilter.losses)
                        Text("Tournaments").tag(MatchFilter.tournaments)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Button(action: {
                        showingDatePicker = true
                    }) {
                        HStack {
                            Text("Date Range")
                            Spacer()
                            Text("\(selectedStartDate.formatted(date: .abbreviated, time: .omitted)) - \(selectedEndDate.formatted(date: .abbreviated, time: .omitted))")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Matches Section
                Section(header: Text("Matches")) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if viewModel.filteredMatches.isEmpty {
                        Text("No matches found")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(viewModel.filteredMatches) { match in
                            NavigationLink(destination: MatchDetailView(match: match)) {
                                MatchHistoryRow(match: match)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Match History")
            .refreshable {
                await viewModel.loadMatches()
            }
            .onChange(of: selectedFilter) { filter in
                switch filter {
                case .all:
                    viewModel.filteredMatches = viewModel.matches
                case .wins:
                    viewModel.filteredMatches = viewModel.matches.filter { $0.isWinner(authService.currentUser?.id ?? "") }
                case .losses:
                    viewModel.filteredMatches = viewModel.matches.filter { !$0.isWinner(authService.currentUser?.id ?? "") }
                case .tournaments:
                    viewModel.filteredMatches = viewModel.matches.filter { $0.tournamentId != nil }
                }
            }
            .onChange(of: selectedStartDate) { _ in
                viewModel.applyDateRange(start: selectedStartDate, end: selectedEndDate)
            }
            .onChange(of: selectedEndDate) { _ in
                viewModel.applyDateRange(start: selectedStartDate, end: selectedEndDate)
            }
            .sheet(isPresented: $showingDatePicker) {
                DateRangePickerView(
                    startDate: $selectedStartDate,
                    endDate: $selectedEndDate,
                    isPresented: $showingDatePicker
                )
            }
            .task {
                await viewModel.loadMatches()
            }
        }
    }
    
    var winRate: Int {
        guard !viewModel.matches.isEmpty else { return 0 }
        let wins = viewModel.matches.filter { $0.isWinner(authService.currentUser?.id ?? "") }.count
        return Int((Double(wins) / Double(viewModel.matches.count)) * 100)
    }
    
    var averageScore: Int {
        guard !viewModel.matches.isEmpty else { return 0 }
        let totalScore = viewModel.matches.reduce(into: 0) { result, match in
            if let score = match.playerScore(for: authService.currentUser?.id ?? "") {
                result += score
            }
        }
        return totalScore / viewModel.matches.count
    }
}

struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        #if os(iOS)
        .background(Color(.systemBackground))
        #elseif os(macOS)
        .background(Color(nsColor: .windowBackgroundColor))
        #endif
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}

struct MatchHistoryRow: View {
    let match: Match
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(match.player1Name) vs \(match.player2Name)")
                    .font(.headline)
                Spacer()
                Text(match.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text("\(match.player1Score ?? 0) - \(match.player2Score ?? 0)")
                    .font(.subheadline)
                Spacer()
                Text("ELO: \((match.eloChange ?? 0) > 0 ? "+" : "")\(match.eloChange ?? 0)")
                    .font(.caption)
                    .foregroundColor((match.eloChange ?? 0) >= 0 ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
}

struct DateRangePickerView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            Form {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)
            }
            .navigationTitle("Select Date Range")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

class MatchHistoryViewModel: ObservableObject {
    @Published var matches: [Match] = []
    @Published var filteredMatches: [Match] = []
    @Published var isLoading = false
    
    var totalMatches: Int {
        matches.count
    }
    
    @MainActor
    func loadMatches() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            matches = try await MatchService.shared.fetchUserMatches()
            filteredMatches = matches
        } catch {
            print("Error loading matches: \(error)")
        }
    }
    
    func applyDateRange(start: Date, end: Date) {
        filteredMatches = matches.filter { match in
            (start...end).contains(match.date)
        }
    }
} 