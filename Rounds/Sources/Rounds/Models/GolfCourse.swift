import Foundation
import CoreLocation

struct GolfCourse: Identifiable, Codable {
    let id: String
    let name: String
    let address: String
    let clubInfo: ClubInfo
    let location: Location
    let scorecard: Scorecard
    let conditions: CourseConditions
    
    struct ClubInfo: Codable {
        let membership: String
        let facilities: [String]
        let website: String?
        let phone: String?
        let email: String?
        
        init(membership: String, facilities: [String], website: String? = nil, phone: String? = nil, email: String? = nil) {
            self.membership = membership
            self.facilities = facilities
            self.website = website
            self.phone = phone
            self.email = email
        }
    }
    
    struct Location: Codable {
        let address: String
        let city: String
        let state: String
        let country: String
        let coordinates: CLLocationCoordinate2D
        
        init(address: String, city: String, state: String, country: String, coordinates: CLLocationCoordinate2D) {
            self.address = address
            self.city = city
            self.state = state
            self.country = country
            self.coordinates = coordinates
        }
        
        enum CodingKeys: String, CodingKey {
            case address, city, state, country
            case latitude
            case longitude
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            address = try container.decode(String.self, forKey: .address)
            city = try container.decode(String.self, forKey: .city)
            state = try container.decode(String.self, forKey: .state)
            country = try container.decode(String.self, forKey: .country)
            let latitude = try container.decode(Double.self, forKey: .latitude)
            let longitude = try container.decode(Double.self, forKey: .longitude)
            coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(address, forKey: .address)
            try container.encode(city, forKey: .city)
            try container.encode(state, forKey: .state)
            try container.encode(country, forKey: .country)
            try container.encode(coordinates.latitude, forKey: .latitude)
            try container.encode(coordinates.longitude, forKey: .longitude)
        }
    }
    
    struct Scorecard: Codable {
        let holes: [Hole]
        let tees: [Tee]
        
        struct Hole: Codable {
            let number: Int
            let par: Int
            let distance: Int
            let handicap: Int
            
            init(number: Int, par: Int, distance: Int, handicap: Int) {
                self.number = number
                self.par = par
                self.distance = distance
                self.handicap = handicap
            }
        }
        
        struct Tee: Codable {
            let name: String
            let rating: Double
            let slope: Int
            let yardage: Int
            
            init(name: String, rating: Double, slope: Int, yardage: Int) {
                self.name = name
                self.rating = rating
                self.slope = slope
                self.yardage = yardage
            }
        }
        
        init(holes: [Hole], tees: [Tee]) {
            self.holes = holes
            self.tees = tees
        }
    }
    
    struct Weather: Codable {
        var temperature: Double
        var windSpeed: Double
        var conditions: String
    }
    
    struct CourseConditions: Codable {
        var weather: Weather
        var greenCondition: String
        var fairwayCondition: String
        var roughCondition: String
        var bunkerCondition: String
        
        init(weather: Weather, greenCondition: String, fairwayCondition: String, roughCondition: String, bunkerCondition: String) {
            self.weather = weather
            self.greenCondition = greenCondition
            self.fairwayCondition = fairwayCondition
            self.roughCondition = roughCondition
            self.bunkerCondition = bunkerCondition
        }
    }
    
    init(id: String = UUID().uuidString,
         name: String,
         address: String,
         clubInfo: ClubInfo,
         location: Location,
         scorecard: Scorecard,
         conditions: CourseConditions) {
        self.id = id
        self.name = name
        self.address = address
        self.clubInfo = clubInfo
        self.location = location
        self.scorecard = scorecard
        self.conditions = conditions
    }
    
    static func createEmpty(id: String = UUID().uuidString, name: String, location: Location, tees: [Tee]) -> GolfCourse {
        GolfCourse(
            id: id,
            name: name,
            address: "",
            clubInfo: ClubInfo(membership: "", facilities: [], website: nil, phone: nil, email: nil),
            location: location,
            scorecard: Scorecard(holes: [], tees: tees),
            conditions: CourseConditions(
                weather: Weather(
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

extension CLLocationCoordinate2D: Codable {
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
} 