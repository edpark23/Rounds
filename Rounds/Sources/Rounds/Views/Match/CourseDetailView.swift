import SwiftUI
import FirebaseFirestore

struct CourseDetailView: View {
    let course: GolfCourse
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTee: GolfCourse.Scorecard.Tee?
    @State private var showingMatchSetup = false
    
    var body: some View {
        Form {
            Section {
                LabeledContent("Name", value: course.name)
                LabeledContent("City", value: course.location.city)
                LabeledContent("State", value: course.location.state)
                if !course.location.address.isEmpty {
                    LabeledContent("Address", value: course.location.address)
                }
            } header: {
                Text("Course Information")
            }
            
            Section {
                ForEach(course.scorecard.tees, id: \.name) { tee in
                    Button(action: {
                        selectedTee = tee
                        showingMatchSetup = true
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(tee.name)
                                    .font(.headline)
                                Text("Rating: \(String(format: "%.1f", tee.rating)) / Slope: \(tee.slope)")
                                    .font(.subheadline)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
            } header: {
                Text("Tees")
            }
        }
        .navigationTitle("Course Details")
        .sheet(isPresented: $showingMatchSetup) {
            if let tee = selectedTee {
                MatchSetupView(course: course, tee: tee)
            }
        }
    }
}

struct Tee: Identifiable, Codable {
    let id: String
    let name: String
    let par: Int
    let rating: Double
    let slope: Int
    let holes: [Hole]
}

struct Hole: Identifiable, Codable {
    let id: String
    let number: Int
    let par: Int
    let distance: Int
    let handicap: Int
} 