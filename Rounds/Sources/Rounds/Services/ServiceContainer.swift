import Foundation

@MainActor
final class ServiceContainer: ObservableObject {
    @Published private(set) var authService: AuthenticationService?
    @Published private(set) var matchService: MatchService?
    @Published private(set) var tournamentService: TournamentService?
    @Published private(set) var golfCourseService: GolfCourseService?
    @Published private(set) var isInitialized = false
    
    static let shared = ServiceContainer()
    
    private init() {}
    
    func initialize() async {
        // Initialize auth service first since other services may depend on it
        authService = AuthenticationService()
        
        // Initialize other services concurrently
        async let matchServiceTask = MatchService.shared
        async let tournamentServiceTask = TournamentService.shared
        async let golfCourseServiceTask = GolfCourseService.shared
        
        // Wait for all services to be initialized
        let (matchService, tournamentService, golfCourseService) = await (
            matchServiceTask,
            tournamentServiceTask,
            golfCourseServiceTask
        )
        
        // Assign the initialized services
        self.matchService = matchService
        self.tournamentService = tournamentService
        self.golfCourseService = golfCourseService
        
        isInitialized = true
    }
} 