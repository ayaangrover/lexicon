import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var navigateToAppView = false

    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 20) {
                // Email and password fields for login
                TextField("Email", text: $email)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)  // Prevent email from capitalizing

                SecureField("Password", text: $password)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                // Show error message if any
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.subheadline)
                }

                // Log In Button
                Button(action: {
                    logIn()
                }) {
                    Text("Log In")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 40)

            // Switch to sign-up
            HStack {
                Text("Don't have an account?")
                    .font(.footnote)
                Button(action: {
                    // Navigate to SignupView
                    navigateToAppView.toggle()
                }) {
                    Text("Sign up")
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
            }

            // Loading indicator (if user is logging in)
            if isLoading {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            }

            Spacer()
        }
        .padding()
        .background(Color.white)
        .fullScreenCover(isPresented: $navigateToAppView) {
            // Navigate to AppView after successful login/signup
            AppView()
        }
    }

    // Login method
    func logIn() {
        isLoading = true
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            isLoading = false
            if let error = error {
                self.errorMessage = "Error: \(error.localizedDescription)"
            } else {
                self.errorMessage = "Logged in successfully!"
                // Navigate to AppView after successful login
                navigateToAppView = true
            }
        }
    }
}
