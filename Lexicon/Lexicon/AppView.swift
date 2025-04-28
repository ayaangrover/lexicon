import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AppView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var isOnboardingComplete: Bool = false
    @State private var isLoading: Bool = true
    @State private var showProfile = false
    @State private var showSettings = false
    @State private var userName: String = "user"
    
    let gridItems = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                
                Color(colorScheme == .dark ? .black : .white)
                    .edgesIgnoringSafeArea(.all)
                if isLoading {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                        .scaleEffect(1.2)
                } else {
                    if isOnboardingComplete {
                        VStack(spacing: 30) {
                            VStack(spacing: 10) {
                                Text("Welcome back, \(userName)!")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text("What will you study today?")
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 40)
                            
                            LazyVGrid(columns: gridItems, spacing: 20) {
                                NavigationLink(destination: QuizletImportView()) {
                                    FeatureButtonView(title: "Import Flashcards from Quizlet")
                                }
                                
                                NavigationLink(destination: MySetsView()) {
                                    FeatureButtonView(title: "View My Sets")
                                }
                                
                                NavigationLink(destination: ChatView()) {
                                    FeatureButtonView(title: "Learn with AI")
                                }
                                
                                NavigationLink(destination: ManualFlashcardCreatorView()) {
                                    FeatureButtonView(title: "Create a Flashcard Set")
                                }
                                
                                NavigationLink(destination: FlashcardGeneratorView()) {
                                    FeatureButtonView(title: "Generate a Flashcard Set")
                                }
                            }
                            .padding()
                            
                            MotivationView()
                            
                            Spacer()
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
                    } else {
                        OnboardingView(isOnboardingComplete: $isOnboardingComplete)
                    }
                }
            }
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
            if let data = snapshot?.data() {
                let onboarding = data["onboardingComplete"] as? Bool ?? false
                if let name = data["name"] as? String {
                    self.userName = name
                }
                completion(onboarding)
            } else {
                completion(false)
            }
        }
    }
}
