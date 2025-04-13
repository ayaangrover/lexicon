import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @State private var userName: String = "User Name"
    @State private var userEmail: String = Auth.auth().currentUser?.email ?? ""
    @State private var photoImage: Image? = Image(systemName: "person.crop.circle")
    @State private var setsStudied: Int = 0
    @State private var signupDate: Date? = nil

    var body: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 20) 
            if let photo = photoImage {
                photo
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            }
            Text(userName)
                .font(.title)
            Text(userEmail)
                .font(.footnote)
                .foregroundColor(Color.gray)
            if let date = signupDate {
                Text("🎉  Thanks for being a member since \(formattedDate(from: date))")
                    .font(.body)
                    .padding(.top, 4)
            }
            StarBadgeView(setsStudied: setsStudied)
            Spacer()
        }
        .padding()
        .onAppear {
            fetchUserProfile()
            fetchSetsStudied()
        }
    }
    
    func fetchUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { document, error in
            if let data = document?.data() {
                if let name = data["name"] as? String {
                    userName = name
                }
                if let email = data["email"] as? String {
                    userEmail = email
                }
                if let base64Photo = data["photoData"] as? String,
                   let imageData = Data(base64Encoded: base64Photo),
                   let uiImage = UIImage(data: imageData) {
                    photoImage = Image(uiImage: uiImage)
                }
            }
            if let creationDate = Auth.auth().currentUser?.metadata.creationDate {
                signupDate = creationDate
            }
        }
    }
    
    func fetchSetsStudied() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { document, error in
            if let data = document?.data(),
               let studied = data["setsStudied"] as? Int {
                setsStudied = studied
            }
        }
    }
    
    func formattedDate(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct StarBadgeView: View {
    var setsStudied: Int
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.fill")
                .font(.system(size: 50))
                .foregroundColor(setsStudied >= 5 ? .yellow : .gray)
            Text("5 Sets Studied")
                .font(.system(size: 16))
                .fontWeight(.medium)
            ProgressView(value: min(Float(setsStudied) / 5.0, 1.0))
                .progressViewStyle(LinearProgressViewStyle(tint: setsStudied >= 5 ? .yellow : .gray))
                .frame(width: 100)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
}
