import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .disableAutocorrection(true)
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                
                Button("Sign In") {
                    Task {
                        await signIn()
                    }
                }
                .disabled(email.isEmpty || password.isEmpty)
                
                Button("Create Account") {
                    showingSignUp = true
                }
            }
            .navigationTitle("Sign In")
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingSignUp) {
                SignUpView(authService: authService)
            }
        }
    }
    
    private func signIn() async {
        do {
            try await authService.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

struct ToolbarHiddenModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 13.0, *) {
            content.toolbar(.hidden)
        } else {
            content
        }
    }
}

@MainActor
class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage = ""
    @Published var showError = false
    
    private let authService: AuthenticationService
    
    init(authService: AuthenticationService? = nil) {
        self.authService = authService ?? AuthenticationService()
    }
    
    func login() async {
        guard !email.isEmpty else {
            errorMessage = "Please enter an email"
            showError = true
            return
        }
        
        guard !password.isEmpty else {
            errorMessage = "Please enter a password"
            showError = true
            return
        }
        
        do {
            try await authService.signIn(email: email, password: password)
            errorMessage = ""
            showError = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
} 