import Foundation

// Models
enum GolfCourseError: LocalizedError {
    case invalidCourseId
    case networkError(String)
    case invalidResponse
    case unauthorized
    case rateLimitExceeded
    case clientError(statusCode: Int)
    case serverError(statusCode: Int)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidCourseId:
            return "Invalid course ID provided"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized: Invalid API key"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later"
        case .clientError(let statusCode):
            return "Client error: \(statusCode)"
        case .serverError(let statusCode):
            return "Server error: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

// API Models
struct SDTournament: Codable {
    let TournamentID: Int
    let Name: String
    let StartDate: String
    let EndDate: String
    let IsOver: Bool?
    let IsInProgress: Bool?
    let Venue: String?
    let Location: String?
    let Par: Int?
    let Yards: Int?
    let Purse: Double?
    let StartDateTime: String?
    let Canceled: Bool?
    let Covered: Bool?
    let City: String?
    let State: String?
    let ZipCode: String?
    let Country: String?
    let TimeZone: String?
    let Format: String?
    let SportRadarTournamentID: String?
    let OddsCoverage: String?
    let Rounds: [SDRound]
}

struct SDRound: Codable {
    let TournamentID: Int
    let RoundID: Int
    let Number: Int
    let Day: String
}

struct SDCourse: Codable {
    let venue: String
    let location: String?
    let par: Int
    let yards: Int
}

struct SDHole: Codable {
    let number: Int
    let par: Int
    let handicap: Int
}

struct SDTee: Codable {
    let name: String
    let color: String
    let rating: Double
    let slope: Int
    let distances: [Int]
}

struct SDCourseConditions: Codable {
    let temperature: Double
    let windSpeed: Double
    let windDirection: String
    let precipitation: Double
    let forecast: String
    let greenSpeed: String
    let fairwayCondition: String
    let roughCondition: String
    let bunkerCondition: String
    let lastUpdated: Date
}

// Domain Models
struct Location {
    let city: String
    let state: String
    
    init(from locationString: String?) {
        if let location = locationString?.split(separator: ",").map(String.init),
           location.count >= 2 {
            self.city = location[0].trimmingCharacters(in: .whitespaces)
            self.state = location[1].trimmingCharacters(in: .whitespaces)
        } else {
            self.city = "Unknown"
            self.state = "Unknown"
        }
    }
}

struct Tee {
    let name: String
    let color: String
    let yards: Int
    let rating: Double
    let slope: Int
}

struct Hole {
    let number: Int
    let par: Int
    let yards: [String: Int]
}

struct Scorecard {
    let holes: [Hole]
    let tees: [Tee]
}

struct GolfCourse {
    let name: String
    let location: Location
    let par: Int
    let yards: Int
}

struct WeatherConditions {
    let temperature: Double
    let windSpeed: Double
    let windDirection: String
    let forecast: String
}

struct CourseConditions {
    let weather: WeatherConditions
    let greenSpeed: String
    let fairwayCondition: String
    let roughCondition: String
    let bunkerCondition: String
    let lastUpdated: Date
}

// Service
class GolfCourseService {
    static let shared = GolfCourseService()
    private let apiKey = "888466edaff84b5ea86a236fcaf4792e"
    private let baseURL = "https://api.sportsdata.io/golf/v2"
    private var courseCache: [String: GolfCourse] = [:]
    
    private init() {}
    
    private func performRequest<T: Decodable>(endpoint: String, queryItems: [URLQueryItem]?) async throws -> T {
        var components = URLComponents(string: endpoint)!
        var allQueryItems = queryItems ?? []
        allQueryItems.append(URLQueryItem(name: "key", value: apiKey))
        components.queryItems = allQueryItems
        
        var request = URLRequest(url: components.url!)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GolfCourseError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            break // Success
        case 401:
            throw GolfCourseError.unauthorized
        case 429:
            throw GolfCourseError.rateLimitExceeded
        case 400...499:
            throw GolfCourseError.clientError(statusCode: httpResponse.statusCode)
        case 500...599:
            throw GolfCourseError.serverError(statusCode: httpResponse.statusCode)
        default:
            throw GolfCourseError.networkError("Unexpected HTTP status code: \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            print("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to convert data to string")")
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw GolfCourseError.decodingError(error)
        }
    }
    
    func searchCourses(query: String) async throws -> [GolfCourse] {
        let endpoint = "\(baseURL)/json/Tournaments"
        let tournaments: [SDTournament] = try await performRequest(endpoint: endpoint, queryItems: nil)
        
        return tournaments
            .filter { $0.Venue?.localizedCaseInsensitiveContains(query) ?? false }
            .map { tournament in
                GolfCourse(
                    name: tournament.Venue ?? "Unknown Venue",
                    location: Location(from: tournament.Location),
                    par: tournament.Par ?? 0,
                    yards: tournament.Yards ?? 0
                )
            }
    }
    
    func getCourseDetails(courseName: String) async throws -> GolfCourse {
        if let cached = courseCache[courseName] {
            return cached
        }
        
        let courses = try await searchCourses(query: courseName)
        guard let course = courses.first(where: { $0.name == courseName }) else {
            throw GolfCourseError.invalidCourseId
        }
        
        courseCache[courseName] = course
        return course
    }
    
    func getCourseConditions(courseId: String) async throws -> CourseConditions {
        let endpoint = "\(baseURL)/json/CourseConditions/\(courseId)"
        let conditions: SDCourseConditions = try await performRequest(endpoint: endpoint, queryItems: nil)
        
        return CourseConditions(
            weather: WeatherConditions(
                temperature: conditions.temperature,
                windSpeed: conditions.windSpeed,
                windDirection: conditions.windDirection,
                forecast: conditions.forecast
            ),
            greenSpeed: conditions.greenSpeed,
            fairwayCondition: conditions.fairwayCondition,
            roughCondition: conditions.roughCondition,
            bunkerCondition: conditions.bunkerCondition,
            lastUpdated: conditions.lastUpdated
        )
    }
}

// Main test
print("Starting golf course API test...")

Task {
    let service = GolfCourseService.shared
    
    do {
        print("Searching for courses containing 'Pebble Beach'...")
        let courses = try await service.searchCourses(query: "Pebble Beach")
        print("Found \(courses.count) courses:")
        for course in courses {
            print("- \(course.name) in \(course.location.city), \(course.location.state)")
            print("  Par: \(course.par), Yards: \(course.yards)")
        }
        
        if let firstCourse = courses.first {
            print("\nGetting details for \(firstCourse.name)...")
            let details = try await service.getCourseDetails(courseName: firstCourse.name)
            print("Course details:")
            print("Name: \(details.name)")
            print("Location: \(details.location.city), \(details.location.state)")
            print("Par: \(details.par)")
            print("Yards: \(details.yards)")
        }
        
    } catch {
        print("Error: \(error.localizedDescription)")
    }
}

// Keep the program running until the async task completes
RunLoop.main.run(until: Date(timeIntervalSinceNow: 5)) 