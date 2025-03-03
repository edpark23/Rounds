import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

enum AuthenticationError: Error {
    case signInError(String)
    case signUpError(String)
    case signOutError(String)
    case userNotFound
}

@MainActor
class AuthenticationService: ObservableObject, @unchecked Sendable {
    static private var _shared: AuthenticationService?
    static var shared: AuthenticationService {
        get async {
            if let service = _shared {
                return service
            }
            let service = await AuthenticationService()
            _shared = service
            return service
        }
    }
    
    @Published var currentUser: Player?
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var stateListener: AuthStateDidChangeListenerHandle?
    private let authStateSubject = PassthroughSubject<User?, Never>()
    
    var authStatePublisher: AnyPublisher<User?, Never> {
        authStateSubject.eraseToAnyPublisher()
    }
    
    init() {
        print("AuthenticationService: Initializing...")
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        stateListener = auth.addStateDidChangeListener { [weak self] _, user in
            self?.authStateSubject.send(user)
            if let user = user {
                Task {
                    do {
                        let player = try await self?.fetchPlayer(userId: user.uid)
                        await MainActor.run {
                            self?.currentUser = player
                        }
                    } catch {
                        print("Error fetching player: \(error)")
                    }
                }
            } else {
                self?.currentUser = nil
            }
        }
    }
    
    func fetchPlayer(userId: String) async throws -> Player {
        let document = try await db.collection("players").document(userId).getDocument()
        guard let player = try? document.data(as: Player.self) else {
            throw NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode player"])
        }
        return player
    }
    
    func signIn(email: String, password: String) async throws {
        print("AuthenticationService: Attempting sign in with email: \(email)")
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            print("AuthenticationService: Sign in successful for user: \(result.user.uid)")
            try await fetchUser(userId: result.user.uid)
        } catch {
            print("AuthenticationService: Sign in failed - \(error.localizedDescription)")
            throw AuthenticationError.signInError(error.localizedDescription)
        }
    }
    
    func signUp(email: String, password: String, displayName: String) async throws {
        print("AuthenticationService: Attempting sign up with email: \(email)")
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            print("AuthenticationService: Sign up successful for user: \(result.user.uid)")
            let newPlayer = Player.createNew(email: email, name: displayName)
            try db.collection("players").document(result.user.uid).setData(from: newPlayer)
            print("AuthenticationService: Player document created in Firestore")
            try await fetchUser(userId: result.user.uid)
        } catch {
            print("AuthenticationService: Sign up failed - \(error.localizedDescription)")
            throw AuthenticationError.signUpError(error.localizedDescription)
        }
    }
    
    func signOut() throws {
        print("AuthenticationService: Attempting sign out")
        do {
            try auth.signOut()
            currentUser = nil
            print("AuthenticationService: Sign out successful")
        } catch {
            print("AuthenticationService: Sign out failed - \(error.localizedDescription)")
            throw AuthenticationError.signOutError(error.localizedDescription)
        }
    }
    
    private func fetchUser(userId: String) async throws {
        print("AuthenticationService: Fetching user document for ID: \(userId)")
        do {
            let document = try await db.collection("players").document(userId).getDocument()
            if let player = try? document.data(as: Player.self) {
                print("AuthenticationService: Successfully fetched player data")
                Task { @MainActor in
                    self.currentUser = player
                }
            } else {
                print("AuthenticationService: Player document exists but failed to decode")
                throw AuthenticationError.userNotFound
            }
        } catch {
            print("AuthenticationService: Failed to fetch user - \(error.localizedDescription)")
            throw AuthenticationError.userNotFound
        }
    }
    
    deinit {
        if let listener = stateListener {
            auth.removeStateDidChangeListener(listener)
        }
    }
} 