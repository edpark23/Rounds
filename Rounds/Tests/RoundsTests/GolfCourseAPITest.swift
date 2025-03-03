import XCTest
@testable import Rounds

final class GolfCourseAPITest: XCTestCase {
    func testSearchCourses() async throws {
        let service = GolfCourseService.shared
        do {
            let courses = try await service.searchCourses(query: "Pebble Beach")
            print("Found \(courses.count) courses")
            for course in courses {
                print("Course: \(course.name) in \(course.location.city), \(course.location.state)")
            }
            XCTAssertFalse(courses.isEmpty, "Should find at least one course")
        } catch {
            print("Error: \(error)")
            XCTFail("API call failed with error: \(error)")
        }
    }
} 