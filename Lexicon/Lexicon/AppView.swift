// Swift
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AppView: View {
    @State private var isOnboardingComplete: Bool = false
    @State private var isLoading: Bool = true
    @State private var showProfile = false
    @State private var showSettings = false
    
    let gridItems = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading...")
                } else {
                    if isOnboardingComplete {
                        VStack {
                            VStack(spacing: 20) {
                                Text("Welcome back, \(Auth.auth().currentUser?.email ?? "No Email")!")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                
                                Text("Main features of the app")
                                    .font(.headline)
                                
                                LazyVGrid(columns: gridItems, spacing: 20) {
                                    NavigationLink(destination: FlashcardGeneratorView()) {
                                        FeatureButtonView(title: "Generate Flashcards with AI")
                                    }
                                    
                                    NavigationLink(destination: QuizletImportView()) {
                                        FeatureButtonView(title: "Import Flashcards from Quizlet")
                                    }
                                    
                                    NavigationLink(destination: MySetsView()) {
                                        FeatureButtonView(title: "View My Sets")
                                    }
                                    
                                    NavigationLink(destination: ChatView()) {
                                        FeatureButtonView(title: "Study with AI")
                                    }
                                    
                                    NavigationLink(destination: ManualFlashcardCreatorView()) {
                                        FeatureButtonView(title: "Create a Flashcard Set")
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding()
                            .navigationBarTitle("", displayMode: .inline)
                            .toolbar {
                                ToolbarItemGroup(placement: .navigationBarLeading) {
                                    Button(action: { showProfile = true }) {
                                        Image(systemName: "person.crop.circle")
                                            .font(.title2)
                                            .foregroundColor(.primary)
                                    }
                                }
                                ToolbarItemGroup(placement: .navigationBarTrailing) {
                                    Button(action: { showSettings = true }) {
                                        Image(systemName: "gearshape")
                                            .font(.title2)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            .sheet(isPresented: $showProfile) {
                                NavigationView { ProfileView() }
                            }
                            .sheet(isPresented: $showSettings) {
                                NavigationView { SettingsView() }
                            }
                        }
                    } else {
                        OnboardingView(isOnboardingComplete: $isOnboardingComplete)
                    }
                }
            }
            .background(Color(UIColor.systemBackground))
        }
        .onAppear {
            checkOnboardingStatus { status in
                self.isOnboardingComplete = status
                self.isLoading = false
            }
        }
    }
}

extension AppView {
    func checkOnboardingStatus(completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
                completion(false)
                return
            }
            if let data = snapshot?.data(), let onboardingComplete = data["onboardingComplete"] as? Bool {
                completion(onboardingComplete)
            } else {
                completion(false)
            }
        }
    }
}

struct FeatureButtonView: View {
    var title: String
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(Color.black)
            .cornerRadius(10)
    }
}
