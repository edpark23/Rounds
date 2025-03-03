import Foundation

class GolfCourseService: ObservableObject {
    static let shared = GolfCourseService()
    private let baseURL = "https://api.sportsdata.io/golf/v2"
    private let apiKey: String = "888466edaff84b5ea86a236fcaf4792e" // TODO: Add your SportsData.io API key here
    
    @Published var nearbyCourses: [GolfCourse] = []
    @Published var recentCourses: [GolfCourse] = []
    
    private init() {}
    
    // MARK: - Course Search
    
    func searchCourses(query: String) async throws -> [GolfCourse] {
        let endpoint = "\(baseURL)/json/Courses"
        let queryItems = [
            URLQueryItem(name: "search", value: query)
        ]
        
        let courses: [SDCourse] = try await performRequest(endpoint: endpoint, queryItems: queryItems)
        return courses.map { $0.toGolfCourse() }
    }
    
    func getNearbyCourses(latitude: Double, longitude: Double, radius: Int = 50) async throws -> [GolfCourse] {
        let endpoint = "\(baseURL)/json/Courses"
        let queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "radius", value: String(radius))
        ]
        
        let courses: [SDCourse] = try await performRequest(endpoint: endpoint, queryItems: queryItems)
        let golfCourses = courses.map { $0.toGolfCourse() }
        
        await MainActor.run {
            self.nearbyCourses = golfCourses
        }
        return golfCourses
    }
    
    func getCourseDetails(courseId: String) async throws -> GolfCourse {
        let endpoint = "\(baseURL)/json/Course/\(courseId)"
        let course: SDCourse = try await performRequest(endpoint: endpoint, queryItems: nil)
        return course.toGolfCourse()
    }
    
    func getCourseConditions(courseId: String) async throws -> GolfCourse.CourseConditions {
        let endpoint = "\(baseURL)/json/CourseConditions/\(courseId)"
        let conditions: SDCourseConditions = try await performRequest(endpoint: endpoint, queryItems: nil)
        return conditions.toGolfCourseConditions()
    }
    
    // MARK: - Recent Courses
    
    func addRecentCourse(_ course: GolfCourse) {
        if !recentCourses.contains(where: { $0.id == course.id }) {
            recentCourses.insert(course, at: 0)
            if recentCourses.count > 5 {
                recentCourses.removeLast()
            }
        }
    }
    
    // MARK: - Helper Methods
    
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
        
        guard httpResponse.statusCode == 200 else {
            throw GolfCourseError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - SportsData.io Models

struct SDCourse: Codable {
    let courseId: Int
    let name: String
    let city: String
    let state: String
    let country: String
    let latitude: Double
    let longitude: Double
    let yardage: Int
    let par: Int
    let holes: [SDHole]
    let tees: [SDTee]
    
    func toGolfCourse() -> GolfCourse {
        GolfCourse(
            id: String(courseId),
            name: name,
            clubInfo: GolfCourse.ClubInfo(
                membership: "Public", // Default to public, update if available
                website: nil,
                phone: nil,
                facilities: []
            ),
            location: GolfCourse.Location(
                address: "",
                city: city,
                state: state,
                country: country,
                latitude: latitude,
                longitude: longitude
            ),
            scorecard: GolfCourse.Scorecard(
                holes: holes.map { hole in
                    GolfCourse.Scorecard.Hole(
                        number: hole.number,
                        par: hole.par,
                        handicap: hole.handicap
                    )
                },
                tees: tees.map { tee in
                    GolfCourse.Scorecard.Tee(
                        name: tee.name,
                        color: tee.color,
                        rating: tee.rating,
                        slope: tee.slope,
                        distances: tee.distances
                    )
                }
            ),
            conditions: GolfCourse.CourseConditions(
                weather: GolfCourse.CourseConditions.Weather(
                    temperature: 0,
                    windSpeed: 0,
                    windDirection: "",
                    precipitation: 0,
                    forecast: ""
                ),
                greenSpeed: "",
                fairwayCondition: "",
                roughCondition: "",
                bunkerCondition: "",
                lastUpdated: Date()
            )
        )
    }
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
    
    func toGolfCourseConditions() -> GolfCourse.CourseConditions {
        GolfCourse.CourseConditions(
            weather: GolfCourse.CourseConditions.Weather(
                temperature: temperature,
                windSpeed: windSpeed,
                windDirection: windDirection,
                precipitation: precipitation,
                forecast: forecast
            ),
            greenSpeed: greenSpeed,
            fairwayCondition: fairwayCondition,
            roughCondition: roughCondition,
            bunkerCondition: bunkerCondition,
            lastUpdated: lastUpdated
        )
    }
}

enum GolfCourseError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from the server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        }
    }
} 