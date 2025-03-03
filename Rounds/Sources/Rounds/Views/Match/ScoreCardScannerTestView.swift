#if os(iOS)
import SwiftUI
import PhotosUI

@available(iOS 13.0, *)
struct ScoreCardScannerTestView: View {
    @StateObject private var scannerService = ScoreCardScannerService()
    @State private var testResults: [TestResult] = []
    @State private var selectedItem: PhotosPickerItem?
    @State private var isShowingScanner = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Test Options")) {
                    Button(action: {
                        isShowingScanner = true
                    }) {
                        Label("Open Live Scanner", systemImage: "camera")
                    }
                    
                    PhotosPicker(selection: $selectedItem,
                               matching: .images) {
                        Label("Select Sample Scorecard", systemImage: "photo")
                    }
                }
                
                if !testResults.isEmpty {
                    Section(header: Text("Test Results")) {
                        ForEach(testResults) { result in
                            VStack(alignment: .leading) {
                                Text(result.title)
                                    .font(.headline)
                                Text(result.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Scanner Test")
            .sheet(isPresented: $isShowingScanner) {
                LiveScannerView(onScan: { result in
                    handleScanResult(result)
                })
            }
            .onChange(of: selectedItem) { item in
                if let item = item {
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            do {
                                let result = try await scannerService.scanScoreCard(image)
                                handleScanResult(result)
                            } catch {
                                showError(error)
                            }
                        }
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func handleScanResult(_ result: ScanResult) {
        testResults.append(TestResult(
            title: "Scan Completed",
            description: """
            Detected Scores:
            Player 1: \(result.player1Score)
            Player 2: \(result.player2Score)
            Confidence: \(Int(result.confidence * 100))%
            """
        ))
    }
    
    private func showError(_ error: Error) {
        errorMessage = error.localizedDescription
        showingError = true
    }
}

struct TestResult: Identifiable {
    let id = UUID()
    let title: String
    let description: String
}

#else
import SwiftUI

struct ScoreCardScannerTestView: View {
    var body: some View {
        VStack {
            Text("Score Card Scanner")
                .font(.title)
                .padding()
            
            Text("Score card scanning is only available on iOS devices.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if os(macOS)
        .background(Color(NSColor.windowBackgroundColor))
        #else
        .background(Color(.systemBackground))
        #endif
    }
}
#endif

#Preview {
    ScoreCardScannerTestView()
} 