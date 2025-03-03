import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authService: AuthenticationService
    
    var body: some View {
        Group {
            if authService.currentUser != nil {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationView {
                MatchQueueView()
            }
            .tabItem {
                Label("Play", systemImage: "figure.golf")
            }
            
            NavigationView {
                TournamentListView()
            }
            .tabItem {
                Label("Tournaments", systemImage: "trophy")
            }
            
            NavigationView {
                StatisticsDashboardView()
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
            }
            
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
        }
    }
} 