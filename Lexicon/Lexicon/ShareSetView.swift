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
                Section(header: Text("Share Set").foregroundColor(.appText)) {
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(Color(red: 63/255, green: 183/255, blue: 154/255))
                }
            }
        }
        .accentColor(Color(red: 63/255, green: 183/255, blue: 154/255))
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
