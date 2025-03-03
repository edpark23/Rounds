import Foundation

enum Configuration {
    enum SportsDataAPI {
        static var apiKey: String {
            // In a production environment, this should be loaded from:
            // - Environment variables
            // - Secure key storage
            // - Configuration file not tracked in git
            // For development, we'll use a property for now
            return "888466edaff84b5ea86a236fcaf4792e"
        }
        
        static let baseURL = "https://api.sportsdata.io/golf/v2"
    }
} 