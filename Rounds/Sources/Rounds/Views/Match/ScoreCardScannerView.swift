#if os(iOS)
import SwiftUI
import PhotosUI

@available(iOS 13.0, *)
struct ScoreCardScannerView: View {
    @StateObject private var scannerService = ScoreCardScannerService()
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var scanResult: ScoreCardScannerService.ScoreCardResult?
    @State private var showingConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let onComplete: ([Int], Int) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            if let image = selectedImage {
                // Show selected image
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(10)
                
                if scannerService.isScanning {
                    ProgressView("Scanning scorecard...")
                } else if let result = scanResult {
                    // Show scan results
                    ScoreCardResultView(result: result) {
                        showingConfirmation = true
                    }
                }
            } else {
                // Show upload prompt
                VStack(spacing: 15) {
                    Image(systemName: "doc.text.viewfinder")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                    
                    Text("Scan Scorecard")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Take a photo or select a scorecard image")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            
            // Photo picker button
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack {
                    Image(systemName: "photo")
                    Text(selectedImage == nil ? "Select Scorecard" : "Select Different Scorecard")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .onChange(of: selectedItem) { item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                    scanResult = nil
                    
                    do {
                        scanResult = try await scannerService.scanScoreCard(image)
                    } catch {
                        errorMessage = error.localizedDescription
                        showingError = true
                    }
                }
            }
        }
        .alert("Confirm Scores", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Submit") {
                if let result = scanResult {
                    onComplete(result.holes, result.totalScore)
                }
            }
        } message: {
            Text("Are you sure these scores are correct?")
        }
        .alert("Scanning Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

struct ScoreCardResultView: View {
    let result: ScoreCardScannerService.ScoreCardResult
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Scanned Scores")
                .font(.headline)
            
            // Front 9
            HStack {
                ForEach(0..<9) { index in
                    Text("\(result.holes[index])")
                        .frame(width: 30)
                        .padding(5)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(5)
                }
            }
            
            // Back 9
            HStack {
                ForEach(9..<18) { index in
                    Text("\(result.holes[index])")
                        .frame(width: 30)
                        .padding(5)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(5)
                }
            }
            
            // Total score
            HStack {
                Text("Total Score:")
                    .fontWeight(.bold)
                Text("\(result.totalScore)")
                    .foregroundColor(.blue)
                    .fontWeight(.bold)
            }
            
            // Confidence indicator
            HStack {
                Text("Confidence:")
                ProgressView(value: result.confidence)
                    .progressViewStyle(.linear)
                    .frame(width: 100)
                Text("\(Int(result.confidence * 100))%")
            }
            .font(.caption)
            .foregroundColor(.gray)
            
            // Confirm button
            Button(action: onConfirm) {
                Text("Confirm Scores")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
        .padding()
    }
}
#else
import SwiftUI

struct ScoreCardScannerView: View {
    let onComplete: ([Int], Int) -> Void
    
    var body: some View {
        Text("Scorecard scanning is only available on iOS")
            .padding()
    }
}
#endif 