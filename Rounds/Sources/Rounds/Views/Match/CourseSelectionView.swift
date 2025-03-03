import SwiftUI
import CoreLocation
import Combine
import FirebaseFirestore

struct CourseSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var golfCourseService = GolfCourseService()
    @State private var selectedCourse: GolfCourse?
    @State private var selectedTee: GolfCourse.Scorecard.Tee?
    @State private var showingMatchSetup = false
    @State private var searchText = ""
    @State private var searchResults: [GolfCourse] = []
    @State private var errorMessage = ""
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Search courses...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: searchText) { _ in
                            searchCourses()
                        }
                }
                
                if !searchResults.isEmpty {
                    Section {
                        ForEach(searchResults) { course in
                            CourseRow(course: course)
                                .onTapGesture {
                                    selectCourse(course)
                                }
                        }
                    } header: {
                        Text("Search Results")
                    }
                }
                
                Section {
                    if nearbyCourses.isEmpty {
                        Text("No nearby courses found")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(nearbyCourses) { course in
                            CourseRow(course: course)
                                .onTapGesture {
                                    selectCourse(course)
                                }
                        }
                    }
                } header: {
                    Text("Nearby Courses")
                }
            }
            .navigationTitle("Select Course")
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingMatchSetup) {
                if let course = selectedCourse, let tee = selectedTee {
                    MatchSetupView(course: course, tee: tee)
                }
            }
        }
    }
    
    private var nearbyCourses: [GolfCourse] {
        golfCourseService.nearbyCourses
    }
    
    private func selectCourse(_ course: GolfCourse) {
        selectedCourse = course
        if let firstTee = course.scorecard.tees.first {
            selectedTee = firstTee
            showingMatchSetup = true
        }
    }
    
    private func searchCourses() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        Task {
            do {
                searchResults = try await golfCourseService.searchCourses(query: searchText)
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

struct CourseRow: View {
    let course: GolfCourse
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(course.name)
                .font(.headline)
            HStack {
                Text("\(course.location.city), \(course.location.state)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct SearchSection: View {
    @Binding var searchText: String
    
    var body: some View {
        Section {
            TextField("Search courses...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct SearchResultsSection: View {
    let searchResults: [GolfCourse]
    @Binding var selectedCourse: GolfCourse?
    @Binding var selectedTee: Tee?
    @Binding var showingMatchSetup: Bool
    
    var body: some View {
        Section("Search Results") {
            if searchResults.isEmpty {
                Text("No courses found")
                    .foregroundColor(.secondary)
            } else {
                ForEach(searchResults) { course in
                    CourseRow(
                        course: course,
                        selectedCourse: $selectedCourse,
                        selectedTee: $selectedTee,
                        showingMatchSetup: $showingMatchSetup
                    )
                }
            }
        }
    }
}

struct RecentCoursesSection: View {
    let recentCourses: [GolfCourse]
    @Binding var selectedCourse: GolfCourse?
    @Binding var selectedTee: Tee?
    @Binding var showingMatchSetup: Bool
    
    var body: some View {
        Section("Recent Courses") {
            if recentCourses.isEmpty {
                Text("No recent courses")
                    .foregroundColor(.secondary)
            } else {
                ForEach(recentCourses) { course in
                    CourseRow(
                        course: course,
                        selectedCourse: $selectedCourse,
                        selectedTee: $selectedTee,
                        showingMatchSetup: $showingMatchSetup
                    )
                }
            }
        }
    }
}

struct NearbyCoursesSection: View {
    let nearbyCourses: [GolfCourse]
    @Binding var selectedCourse: GolfCourse?
    @Binding var selectedTee: Tee?
    @Binding var showingMatchSetup: Bool
    
    var body: some View {
        Section("Nearby Courses") {
            if nearbyCourses.isEmpty {
                Text("No nearby courses")
                    .foregroundColor(.secondary)
            } else {
                ForEach(nearbyCourses) { course in
                    CourseRow(
                        course: course,
                        selectedCourse: $selectedCourse,
                        selectedTee: $selectedTee,
                        showingMatchSetup: $showingMatchSetup
                    )
                }
            }
        }
    }
}

struct CourseConditionsView: View {
    let course: GolfCourse
    let match: Match
    let onComplete: () -> Void
    
    @StateObject private var viewModel = CourseConditionsViewModel()
    @EnvironmentObject private var matchService: MatchService
    @EnvironmentObject private var golfCourseService: GolfCourseService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // Tee Selection
                Section("Tee Selection") {
                    Picker("Tee", selection: $viewModel.selectedTee) {
                        ForEach(course.scorecard.tees, id: \.name) { tee in
                            Text("\(tee.name) (\(tee.color))")
                                .tag(tee)
                        }
                    }
                }
                
                // Weather Conditions
                Section("Weather Conditions") {
                    if let conditions = viewModel.conditions?.weather {
                        LabeledContent("Temperature", value: "\(Int(conditions.temperature))°F")
                        LabeledContent("Wind", value: "\(Int(conditions.windSpeed)) mph \(conditions.windDirection)")
                        LabeledContent("Precipitation", value: "\(Int(conditions.precipitation))%")
                        LabeledContent("Forecast", value: conditions.forecast)
                    } else {
                        ProgressView()
                    }
                }
                
                // Course Conditions
                Section("Course Conditions") {
                    if let conditions = viewModel.conditions {
                        LabeledContent("Green Speed", value: conditions.greenSpeed)
                        LabeledContent("Fairway", value: conditions.fairwayCondition)
                        LabeledContent("Rough", value: conditions.roughCondition)
                        LabeledContent("Bunkers", value: conditions.bunkerCondition)
                        Text("Last updated: \(conditions.lastUpdated.formatted())")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        ProgressView()
                    }
                }
            }
            .navigationTitle(course.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start Match") {
                        Task {
                            await viewModel.startMatch(match: match, course: course, matchService: matchService, golfCourseService: golfCourseService)
                            dismiss()
                            onComplete()
                        }
                    }
                    .disabled(viewModel.selectedTee == nil)
                }
            }
            .task {
                await viewModel.loadConditions(courseId: course.id, using: golfCourseService)
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

@MainActor
class CourseSelectionViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [GolfCourse] = []
    @Published var recentCourses: [GolfCourse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let locationManager = CLLocationManager()
    
    init() {
        locationManager.requestWhenInUseAuthorization()
        
        // Debounce search query
        Task {
            #if os(iOS)
            for await _ in NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification).values {
                if !searchText.isEmpty {
                    await search()
                } else {
                    await MainActor.run {
                        searchResults = []
                    }
                }
            }
            #else
            // On macOS, we'll rely on direct binding to searchText
            // The TextField binding will automatically trigger search
            $searchText
                .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
                .sink { [weak self] query in
                    guard let self = self else { return }
                    if !query.isEmpty {
                        Task {
                            await self.search()
                        }
                    } else {
                        self.searchResults = []
                    }
                }
                .store(in: &cancellables)
            #endif
        }
    }
    
    var nearbyCourses: [GolfCourse] {
        golfCourseService.nearbyCourses
    }
    
    var selectedCourse: GolfCourse?
    var isSearching = false
    var showingError = false
    
    private var cancellables = Set<AnyCancellable>()
    
    func loadNearbyCourses(using golfCourseService: GolfCourseService) async {
        isLoading = true
        defer { isLoading = false }
        
        guard let location = locationManager.location else {
            errorMessage = "Unable to access location"
            showingError = true
            return
        }
        
        do {
            golfCourseService.nearbyCourses = try await golfCourseService.getNearbyCourses(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    @MainActor
    private func search() async {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        defer { isSearching = false }
        
        do {
            searchResults = try await golfCourseService.searchCourses(query: searchText)
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

@MainActor
class CourseConditionsViewModel: ObservableObject {
    @Published var selectedTee: GolfCourse.Scorecard.Tee?
    @Published var conditions: GolfCourse.CourseConditions?
    @Published var showingError = false
    @Published var errorMessage: String?
    
    private let locationManager = CLLocationManager()
    
    init() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func loadConditions(courseId: String, using golfCourseService: GolfCourseService) async {
        do {
            conditions = try await golfCourseService.getCourseConditions(courseId: courseId)
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    func startMatch(match: Match, course: GolfCourse, matchService: MatchService, golfCourseService: GolfCourseService) async {
        guard let selectedTee = selectedTee else { return }
        
        do {
            // Update match with course and tee information
            var updatedMatch = match
            updatedMatch.courseId = course.id
            updatedMatch.courseName = course.name
            updatedMatch.selectedTee = selectedTee.name
            updatedMatch.courseRating = selectedTee.rating
            updatedMatch.courseSlope = selectedTee.slope
            
            try await matchService.updateMatch(updatedMatch)
            golfCourseService.addRecentCourse(course)
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
} 