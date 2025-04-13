import SwiftUI
import FirebaseAuth
import FirebaseCore

class SessionStore: ObservableObject {
    @Published var user: User?
    
    init() {
        listen()
    }
    
    func listen() {
        Auth.auth().addStateDidChangeListener { auth, user in
            self.user = user
        }
    }
}

@main
struct LexiconApp: App {
    @StateObject var session = SessionStore()
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if session.user != nil {
                AppView()
                    .environmentObject(session)
            } else {
                ContentView()
                    .environmentObject(session)
            }
        }
    }
}
