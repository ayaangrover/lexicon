import SwiftUI
import FirebaseFirestore

struct ShareSetView: View {
    var set: FlashcardSet
    @Environment(\.presentationMode) var presentationMode
    @State private var email: String = ""
    @State private var errorMessage: String = ""
    @State private var isSharing: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Share Set")) {
                    TextField("Email address to share with", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
                Section {
                    Button(isSharing ? "Sharing..." : "Share") {
                        shareSet()
                    }
                    .disabled(isSharing || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Share Set")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    func shareSet() {
        isSharing = true
        errorMessage = ""
        let db = Firestore.firestore()
        let shareData: [String: Any] = [
            "sharedWith": FieldValue.arrayUnion([email.trimmingCharacters(in: .whitespacesAndNewlines)])
        ]
        db.collection("flashcardSets").document(set.id).updateData(shareData) { error in
            isSharing = false
            if let error = error {
                errorMessage = "Error sharing set: \(error.localizedDescription)"
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}