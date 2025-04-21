import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Button("Log Out") {
                    do {
                        try Auth.auth().signOut()
                        NotificationCenter.default.post(name: NSNotification.Name("UserSignedOut"), object: nil)
                        presentationMode.wrappedValue.dismiss()
                    } catch {
                        errorMessage = "Failed to sign out: \(error.localizedDescription)"
                    }
                }
                .padding()
                .background(Color.appText)
                .foregroundColor(.appBackground)
                .cornerRadius(10)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
                Spacer()
            }
            .navigationBarTitle("Settings", displayMode: .inline)
        }
    }
}
