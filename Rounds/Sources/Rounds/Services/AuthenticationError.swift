enum AuthenticationError: Error {
    case signOutError(String)
    case userNotFound
    case notLoggedIn
    case invalidEmail
    case invalidPassword
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case unknown(String)
} 