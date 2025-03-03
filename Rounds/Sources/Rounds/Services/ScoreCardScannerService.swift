#if os(iOS)
import Foundation
import Vision
import UIKit

class ScoreCardScannerService: ObservableObject {
    @Published var isScanning = false
    @Published var error: String?
    
    struct ScoreCardResult {
        var holes: [Int]
        var totalScore: Int
        var confidence: Double
    }
    
    /// Scan a golf scorecard image and extract hole scores
    /// - Parameter image: UIImage of the scorecard
    /// - Returns: Extracted scores and confidence level
    func scanScoreCard(_ image: UIImage) async throws -> ScoreCardResult {
        isScanning = true
        defer { isScanning = false }
        
        guard let cgImage = image.cgImage else {
            throw ScannerError.invalidImage
        }
        
        // Create request handler
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        
        // Create text recognition request
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false // Disable language correction for numbers
        request.minimumTextHeight = 0.01 // Adjust based on typical scorecard text size
        
        // Perform request
        try await requestHandler.perform([request])
        
        // Process results
        guard let observations = request.results else {
            throw ScannerError.noTextFound
        }
        
        return try processObservations(observations)
    }
    
    /// Process text recognition results
    private func processObservations(_ observations: [VNRecognizedTextObservation]) throws -> ScoreCardResult {
        var numbers: [(text: String, boundingBox: CGRect)] = []
        
        // Extract all numbers and their positions
        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else { continue }
            
            // Convert normalized coordinates to absolute coordinates
            let boundingBox = CGRect(
                x: observation.boundingBox.minX,
                y: observation.boundingBox.minY,
                width: observation.boundingBox.width,
                height: observation.boundingBox.height
            )
            
            // Only process if it looks like a golf score (1-2 digits, 1-12)
            if let number = Int(candidate.string),
               (1...12).contains(number) {
                numbers.append((candidate.string, boundingBox))
            }
        }
        
        // Sort numbers by position (left to right, top to bottom)
        let sortedNumbers = sortNumbersByPosition(numbers)
        
        // Extract hole scores
        var holes: [Int] = []
        var totalConfidence = 0.0
        var count = 0
        
        for (text, _) in sortedNumbers {
            if let score = Int(text) {
                holes.append(score)
                count += 1
                if count == 18 { break } // Stop after 18 holes
            }
        }
        
        // Validate results
        guard holes.count == 18 else {
            throw ScannerError.invalidHoleCount(holes.count)
        }
        
        let totalScore = holes.reduce(0, +)
        let confidence = calculateConfidence(holes)
        
        return ScoreCardResult(
            holes: holes,
            totalScore: totalScore,
            confidence: confidence
        )
    }
    
    /// Sort numbers based on their position on the scorecard
    private func sortNumbersByPosition(_ numbers: [(text: String, boundingBox: CGRect)]) -> [(String, CGRect)] {
        // Sort primarily by Y position (top to bottom)
        // For similar Y positions, sort by X position (left to right)
        return numbers.sorted { first, second in
            let yDiff = abs(first.boundingBox.midY - second.boundingBox.midY)
            if yDiff < 0.05 { // If Y positions are similar
                return first.boundingBox.midX < second.boundingBox.midX
            }
            return first.boundingBox.midY > second.boundingBox.midY
        }
    }
    
    /// Calculate confidence score based on the extracted holes
    private func calculateConfidence(_ holes: [Int]) -> Double {
        // Basic validation rules for golf scores
        var confidence = 1.0
        
        // Penalize for unlikely golf scores
        for score in holes {
            if score > 8 { // Most golf scores are 8 or less
                confidence *= 0.9
            }
        }
        
        // Check for reasonable total
        let total = holes.reduce(0, +)
        if total < 50 || total > 150 {
            confidence *= 0.7
        }
        
        return max(0.0, min(1.0, confidence))
    }
}

enum ScannerError: Error, LocalizedError {
    case invalidImage
    case noTextFound
    case invalidHoleCount(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid or corrupted image"
        case .noTextFound:
            return "No text found in the image"
        case .invalidHoleCount(let count):
            return "Invalid number of holes found: \(count). Expected 18."
        }
    }
}
#else
import Foundation

// Stub implementation for macOS
class ScoreCardScannerService: ObservableObject {
    @Published var isScanning = false
    @Published var error: String?
    
    struct ScoreCardResult {
        var holes: [Int]
        var totalScore: Int
        var confidence: Double
    }
}
#endif 