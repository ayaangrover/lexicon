import SwiftUI
import FirebaseAuth

struct SignupView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var navigateToAppView = false

    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 20) {
                // Email and password fields for sign-up
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

                // Sign Up Button
                Button(action: {
                    signUp()
                }) {
                    Text("Sign Up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 40)

            // Switch to login
            HStack {
                Text("Already have an account?")
                    .font(.footnote)
                Button(action: {
                    // Navigate to LoginView
                    navigateToAppView.toggle()
                }) {
                    Text("Log in")
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
            }

            // Loading indicator (if user is signing up)
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
            // Navigate to AppView after successful signup
            AppView()
        }
    }

    // Sign-up method
    func signUp() {
        isLoading = true
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            isLoading = false
            if let error = error {
                self.errorMessage = "Error: \(error.localizedDescription)"
            } else {
                self.errorMessage = "User created successfully!"
                // Navigate to AppView after successful sign-up
                navigateToAppView = true
            }
        }
    }
}
