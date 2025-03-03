import Foundation
import FirebaseFirestore
import CoreLocation

@MainActor
class GolfCourseService: ObservableObject {
    private let db = Firestore.firestore()
    
    @Published var courses: [GolfCourse] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var nearbyCourses: [GolfCourse] = []
    
    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }
    
    func fetchCourses() async throws {
        isLoading = true
        defer { isLoading = false }
        
        let snapshot = try await db.collection("courses").getDocuments()
        courses = try snapshot.documents.compactMap { document in
            try document.data(as: GolfCourse.self)
        }
    }
    
    func createCourse(from data: [String: Any]) throws -> GolfCourse {
        let courseId = data["courseId"] as? Int ?? 0
        let name = data["name"] as? String ?? ""
        let address = data["address"] as? String ?? ""
        let city = data["city"] as? String ?? ""
        let state = data["state"] as? String ?? ""
        let country = data["country"] as? String ?? ""
        let latitude = data["latitude"] as? Double ?? 0
        let longitude = data["longitude"] as? Double ?? 0
        let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        let holes = (data["holes"] as? [[String: Any]] ?? []).map { hole in
            GolfCourse.Scorecard.Hole(
                number: hole["number"] as? Int ?? 0,
                par: hole["par"] as? Int ?? 0,
                distance: hole["distance"] as? Int ?? 0,
                handicap: hole["handicap"] as? Int ?? 0
            )
        }
        
        let tees = (data["tees"] as? [[String: Any]] ?? []).map { tee in
            GolfCourse.Scorecard.Tee(
                name: tee["name"] as? String ?? "",
                rating: tee["rating"] as? Double ?? 0,
                slope: tee["slope"] as? Int ?? 0,
                yardage: tee["yardage"] as? Int ?? 0
            )
        }
        
        return GolfCourse(
            id: String(courseId),
            name: name,
            address: address,
            clubInfo: GolfCourse.ClubInfo(
                membership: "Public",
                facilities: [],
                website: nil,
                phone: nil,
                email: nil
            ),
            location: GolfCourse.Location(
                address: address,
                city: city,
                state: state,
                country: country,
                coordinates: coordinates
            ),
            scorecard: GolfCourse.Scorecard(
                holes: holes,
                tees: tees
            ),
            conditions: GolfCourse.CourseConditions(
                weather: GolfCourse.Weather(
                    temperature: 0,
                    windSpeed: 0,
                    conditions: ""
                ),
                greenCondition: "",
                fairwayCondition: "",
                roughCondition: "",
                bunkerCondition: ""
            )
        )
    }
    
    func getNearbyCourses(latitude: Double, longitude: Double) async throws -> [GolfCourse] {
        // Implementation will be added later
        return []
    }
    
    func searchCourses(query: String) async throws -> [GolfCourse] {
        // Implementation will be added later
        return []
    }
    
    func getCourseConditions(courseId: String) async throws -> GolfCourse.CourseConditions {
        // Implementation will be added later
        return GolfCourse.CourseConditions(
            weather: GolfCourse.Weather(
                temperature: 0,
                windSpeed: 0,
                conditions: "Unknown"
            ),
            greenCondition: "Unknown",
            fairwayCondition: "Unknown",
            roughCondition: "Unknown",
            bunkerCondition: "Unknown"
        )
    }
    
    func addRecentCourse(_ course: GolfCourse) {
        // Implementation will be added later
    }
}

// MARK: - Error Types

enum GolfCourseError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case unauthorized
    case rateLimitExceeded
    case clientError(statusCode: Int)
    case serverError(statusCode: Int)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from the server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
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
            address: "",
            clubInfo: GolfCourse.ClubInfo(
                membership: "Public",
                facilities: [],
                website: nil,
                phone: nil,
                email: nil
            ),
            location: GolfCourse.Location(
                address: "",
                city: city,
                state: state,
                country: country,
                coordinates: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            ),
            scorecard: GolfCourse.Scorecard(
                holes: holes.map { hole in
                    GolfCourse.Scorecard.Hole(
                        number: hole.number,
                        par: hole.par,
                        distance: hole.distance,
                        handicap: hole.handicap
                    )
                },
                tees: tees.map { tee in
                    GolfCourse.Scorecard.Tee(
                        name: tee.name,
                        rating: tee.rating,
                        slope: tee.slope,
                        yardage: tee.yardage
                    )
                }
            ),
            conditions: GolfCourse.CourseConditions(
                weather: GolfCourse.Weather(
                    temperature: 0,
                    windSpeed: 0,
                    conditions: ""
                ),
                greenCondition: "",
                fairwayCondition: "",
                roughCondition: "",
                bunkerCondition: ""
            )
        )
    }
}

struct SDHole: Codable {
    let number: Int
    let par: Int
    let handicap: Int
    let distance: Int
}

struct SDTee: Codable {
    let name: String
    let color: String
    let rating: Double
    let slope: Int
    let yardage: Int
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
            weather: GolfCourse.Weather(
                temperature: temperature,
                windSpeed: windSpeed,
                conditions: forecast
            ),
            greenCondition: greenSpeed,
            fairwayCondition: fairwayCondition,
            roughCondition: roughCondition,
            bunkerCondition: bunkerCondition
        )
    }
} 