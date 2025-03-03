import Foundation

enum AuthError: LocalizedError {
    case passwordMismatch
    case invalidEmail
    case weakPassword
    case userNotFound
    case emailAlreadyInUse
    case networkError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .passwordMismatch:
            return "Passwords do not match"
        case .invalidEmail:
            return "Invalid email address"
        case .weakPassword:
            return "Password is too weak"
        case .userNotFound:
            return "User not found"
        case .emailAlreadyInUse:
            return "Email is already in use"
        case .networkError:
            return "Network error occurred"
        case .unknown(let message):
            return message
        }
    }
} 