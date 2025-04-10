import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct OnboardingView: View {
    @State private var currentStep: Int = 1
    @State private var name: String = ""
    @State private var photo: Image? = nil
    @State private var inputImage: UIImage? = nil
    @State private var showImagePicker: Bool = false
    @State private var errorMessage: String = ""
    @Binding var isOnboardingComplete: Bool

    var body: some View {
        NavigationView {
            VStack {
                switch currentStep {
                case 1:
                    onboardingStep1
                case 2:
                    onboardingStep2
                default:
                    onboardingStep1
                }
            }
            .navigationBarTitle("Onboarding", displayMode: .inline)
        }
        .sheet(isPresented: $showImagePicker, onDismiss: loadImage) {
            ImagePicker(image: $inputImage)
        }
    }

    private var onboardingStep1: some View {
        VStack(spacing: 20) {
            Text("Step 1: Your Details")
                .font(.headline)
            TextField("Enter your name", text: $name)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            if let photo = photo {
                photo
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                Text("No photo selected")
                    .foregroundColor(.gray)
                    .padding()
            }
            Button("Choose Photo") {
                showImagePicker = true
            }
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            Button("Next Step") {
                if name.trimmingCharacters(in: .whitespaces).isEmpty {
                    errorMessage = "Name is required."
                } else {
                    errorMessage = ""
                    currentStep = 2
                }
            }
            .padding()
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }

    private var onboardingStep2: some View {
        VStack(spacing: 20) {
            Text("Step 2: Confirm Details")
                .font(.headline)
            if let photo = photo {
                photo
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
            }
            Text("Name: \(name)")
                .font(.title2)
            Button("Finish Onboarding") {
                updateUserProfile()
            }
            .padding()
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }

    func loadImage() {
        guard let inputImage = inputImage else { return }
        photo = Image(uiImage: inputImage)
    }
    
    func updateUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in."
            print("Update failed: User not logged in.")
            return
        }
        print("Updating profile for uid: \(uid)")
        
        let db = Firestore.firestore()
        
        if let image = inputImage {
            // Compress the image to JPEG with quality 0.5
            guard let imageData = image.jpegData(compressionQuality: 0.5) else {
                errorMessage = "Could not compress image."
                return
            }
            // Convert image data to Base64 string
            let base64String = imageData.base64EncodedString()
            
            let profileData: [String: Any] = [
                "name": name,
                "onboardingComplete": true,
                "photoData": base64String
            ]
            
            db.collection("users").document(uid).setData(profileData, merge: true) { err in
                if let err = err {
                    DispatchQueue.main.async {
                        errorMessage = "Error saving profile: \(err.localizedDescription)"
                    }
                    print("Error saving profile: \(err.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        isOnboardingComplete = true
                    }
                    print("Profile updated successfully with encoded photo.")
                }
            }
        } else {
            let profileData: [String: Any] = [
                "name": name,
                "onboardingComplete": true
            ]
            db.collection("users").document(uid).setData(profileData, merge: true) { err in
                if let err = err {
                    DispatchQueue.main.async {
                        errorMessage = "Error saving profile: \(err.localizedDescription)"
                    }
                    print("Error saving profile: \(err.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        isOnboardingComplete = true
                    }
                    print("Profile updated successfully without photo.")
                }
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(isOnboardingComplete: .constant(false))
    }
}
