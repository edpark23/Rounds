import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SignUpViewModel
    
    init(authService: AuthenticationService) {
        _viewModel = StateObject(wrappedValue: SignUpViewModel(authService: authService))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Create Account")
                    .font(.largeTitle)
                    .padding(.bottom)
                
                VStack(spacing: 20) {
                    RoundsTextField(placeholder: "Name", text: $name)
                    RoundsTextField(placeholder: "Email", text: $email)
                    RoundsTextField(placeholder: "Password", text: $password, isSecure: true)
                    RoundsTextField(placeholder: "Confirm Password", text: $confirmPassword, isSecure: true)
                }
                .padding(.horizontal)
                
                Button(action: {
                    Task {
                        await signUp()
                    }
                }) {
                    Text("Sign Up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                
                if showingError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                Button("Already have an account? Log in") {
                    dismiss()
                }
                .padding()
            }
        }
    }
    
    @MainActor
    private func signUp() async {
        guard !name.isEmpty else {
            errorMessage = "Please enter your name"
            showingError = true
            return
        }
        
        guard !email.isEmpty else {
            errorMessage = "Please enter an email"
            showingError = true
            return
        }
        
        guard !password.isEmpty else {
            errorMessage = "Please enter a password"
            showingError = true
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            showingError = true
            return
        }
        
        do {
            try await viewModel.signUp()
            errorMessage = ""
            showingError = false
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

@MainActor
class SignUpViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var displayName = ""
    @Published var errorMessage = ""
    @Published var isLoading = false
    @Published var showingError = false
    
    let authService: AuthenticationService
    
    init(authService: AuthenticationService) {
        self.authService = authService
    }
    
    func signUp() async throws {
        guard password == confirmPassword else {
            throw AuthError.passwordMismatch
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await authService.signUp(email: email, password: password, displayName: displayName)
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
            throw error
        }
    }
} 