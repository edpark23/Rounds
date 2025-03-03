import SwiftUI

struct CreateTournamentView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateTournamentViewModel
    @EnvironmentObject private var tournamentService: TournamentService
    @EnvironmentObject private var authService: AuthenticationService
    
    init() {
        self._viewModel = StateObject(wrappedValue: CreateTournamentViewModel())
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Info Section
                Section(header: Text("Tournament Info")) {
                    TextField("Tournament Name", text: $viewModel.tournamentName)
                    
                    TextEditor(text: $viewModel.description)
                        .frame(height: 100)
                }
                
                // Format Section
                Section(header: Text("Format")) {
                    Picker("Tournament Format", selection: $viewModel.format) {
                        Text("Single Elimination").tag(Tournament.TournamentFormat.singleElimination)
                        Text("Double Elimination").tag(Tournament.TournamentFormat.doubleElimination)
                        Text("Round Robin").tag(Tournament.TournamentFormat.roundRobin)
                        Text("Swiss").tag(Tournament.TournamentFormat.swiss)
                    }
                }
                
                // Date Section
                Section(header: Text("Schedule")) {
                    DatePicker("Start Date", selection: $viewModel.startDate, in: Date()...)
                    DatePicker("End Date", selection: $viewModel.endDate, in: viewModel.startDate...)
                }
                
                // Venue Section
                Section(header: Text("Venue")) {
                    TextField("Venue", text: $viewModel.venue)
                    TextField("Location", text: $viewModel.location)
                }
                
                // Course Details Section
                Section(header: Text("Course Details")) {
                    Stepper("Par", value: $viewModel.par, in: 72...108)
                    Stepper("Yardage", value: $viewModel.yardage, in: 7200...10800)
                }
                
                // Purse Section
                Section(header: Text("Purse")) {
                    TextField("Purse", value: $viewModel.purse, format: .number)
                }
                
                // Time Zone Section
                Section(header: Text("Time Zone")) {
                    TextField("Time Zone", text: $viewModel.timeZone)
                }
                
                // Players Section
                Section(header: Text("Players")) {
                    Stepper("Minimum Players: \(viewModel.minPlayers)", value: $viewModel.minPlayers, in: 4...32)
                    Stepper("Maximum Players: \(viewModel.maxPlayers)", value: $viewModel.maxPlayers, in: viewModel.minPlayers...32)
                }
                
                // Entry Fee Section
                Section(header: Text("Entry Fee")) {
                    Toggle("Has Entry Fee", isOn: $viewModel.hasEntryFee)
                    
                    if viewModel.hasEntryFee {
                        Stepper("Entry Fee: $\(viewModel.entryFee)", value: $viewModel.entryFee, in: 1...1000)
                    }
                }
                
                // Rules Section
                Section(header: Text("Rules")) {
                    ForEach(viewModel.rules.indices, id: \.self) { index in
                        HStack {
                            TextField("Rule \(index + 1)", text: $viewModel.rules[index])
                            
                            Button(action: {
                                viewModel.rules.remove(at: index)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    Button(action: {
                        viewModel.rules.append("")
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Rule")
                        }
                    }
                }
            }
            .navigationTitle("Create Tournament")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            await viewModel.createTournament(using: tournamentService, authService: authService)
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.isValid)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

@MainActor
class CreateTournamentViewModel: ObservableObject {
    @Published var tournamentName = ""
    @Published var description = ""
    @Published var format: Tournament.TournamentFormat = .singleElimination
    @Published var startDate = Date()
    @Published var endDate = Date().addingTimeInterval(86400) // Next day
    @Published var venue = ""
    @Published var location = ""
    @Published var par = 72
    @Published var yardage = 7200
    @Published var purse = 0.0
    @Published var timeZone = TimeZone.current.identifier
    @Published var minPlayers = 4
    @Published var maxPlayers = 8
    @Published var hasEntryFee = false
    @Published var entryFee = 10
    @Published var rules: [String] = ["Standard golf rules apply"]
    
    @Published var showError = false
    @Published var errorMessage = ""
    
    init() {}
    
    var isValid: Bool {
        !tournamentName.isEmpty &&
        !description.isEmpty &&
        !venue.isEmpty &&
        !location.isEmpty &&
        !rules.contains(where: { $0.isEmpty }) &&
        startDate < endDate &&
        minPlayers <= maxPlayers
    }
    
    func createTournament(using tournamentService: TournamentService, authService: AuthenticationService) async {
        guard let userId = authService.currentUser?.id else {
            errorMessage = "You must be logged in to create a tournament"
            showError = true
            return
        }
        
        let tournament = Tournament(
            id: nil,
            name: tournamentName,
            description: description,
            startDate: startDate,
            endDate: endDate,
            venue: venue,
            location: location,
            par: par,
            yardage: yardage,
            purse: purse,
            timeZone: timeZone,
            format: format,
            status: .registration,
            participants: [userId], // Creator is automatically registered
            rounds: [],
            creatorId: userId,
            minPlayers: minPlayers,
            maxPlayers: maxPlayers,
            entryFee: hasEntryFee ? entryFee : nil,
            prizePool: hasEntryFee ? nil : nil, // Will be calculated when tournament starts
            rules: rules.filter { !$0.isEmpty },
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            _ = try await tournamentService.createTournament(tournament)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
} 