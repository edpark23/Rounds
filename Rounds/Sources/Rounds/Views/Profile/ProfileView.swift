import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var showingSignOutAlert = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            if let player = authService.currentUser {
                List {
                    Section {
                        HStack {
                            Text("Display Name")
                            Spacer()
                            Text(player.name)
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(player.email)
                                .foregroundColor(.gray)
                        }
                    } header: {
                        Text("Player Info")
                    }
                    
                    Section {
                        HStack {
                            Text("ELO Rating")
                            Spacer()
                            Text("\(player.eloRating)")
                        }
                        HStack {
                            Text("Matches Played")
                            Spacer()
                            Text("\(player.matchesPlayed)")
                        }
                        HStack {
                            Text("Win/Loss")
                            Spacer()
                            Text("\(player.matchesWon)/\(player.matchesLost)")
                        }
                    } header: {
                        Text("Statistics")
                    }
                    
                    Section {
                        Button(role: .destructive) {
                            showingSignOutAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Sign Out")
                                Spacer()
                            }
                        }
                    }
                }
                .navigationTitle("Profile")
                .alert("Sign Out", isPresented: $showingSignOutAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Sign Out", role: .destructive) {
                        do {
                            try authService.signOut()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                } message: {
                    Text("Are you sure you want to sign out?")
                }
                .alert("Error", isPresented: .init(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )) {
                    Button("OK", role: .cancel) { }
                } message: {
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                    }
                }
            } else {
                Text("Loading profile...")
            }
        }
    }
} 