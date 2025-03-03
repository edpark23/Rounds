import SwiftUI
import FirebaseCore

@main
struct RoundsApp: App {
    @StateObject private var serviceContainer = ServiceContainer.shared
    @State private var isInitializing = true
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isInitializing {
                    ProgressView("Initializing...")
                } else {
                    if let authService = serviceContainer.authService,
                       let matchService = serviceContainer.matchService,
                       let tournamentService = serviceContainer.tournamentService,
                       let golfCourseService = serviceContainer.golfCourseService {
                        ContentView()
                            .environmentObject(authService)
                            .environmentObject(matchService)
                            .environmentObject(tournamentService)
                            .environmentObject(golfCourseService)
                    }
                }
            }
            .task {
                await serviceContainer.initialize()
                isInitializing = false
            }
        }
    }
} 