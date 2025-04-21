
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "book.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(Color.appText)
                    .padding(.top, 60)
                
                Text("Lexicon")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.appText)
                
                Text("Your AI-powered study companion")
                    .font(.headline)
                    .foregroundColor(Color.appText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                TabView {
                    FeatureRow(icon: "menucard", title: "Smart Flashcards", description: "Study smarter with AI-powered flashcards.")
                    FeatureRow(icon: "note.text", title: "AI-Summarized Notes", description: "Get concise summaries of your notes.")
                    FeatureRow(icon: "timer", title: "Pomodoro Study Timer", description: "Boost productivity with Pomodoro timer.")
                    FeatureRow(icon: "calendar", title: "Homework & Exam Tracker", description: "Keep track of assignments and exams.")
                    FeatureRow(icon: "brain.head.profile", title: "AI Tutor & Quiz Generator", description: "Personalized quizzes and tutoring.")
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .padding()
                
                VStack(spacing: 15) {
                    NavigationLink(destination: LoginView()) {
                        Text("Log In")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(Color.appText)
                    }
                    .buttonStyle(AppButtonStyle())

                    NavigationLink(destination: SignupView()) {
                        Text("Sign Up")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(Color.appText)
                    }
                    .buttonStyle(AppButtonStyle())
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding()
            .background(Color.appBackground.ignoresSafeArea())
        }
    }
}

struct FeatureRow: View {
    var icon: String
    var title: String
    var description: String
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(Color.appText)
            Text(title)
                .font(.headline)
                .foregroundColor(Color.appText)
                .padding(.top, 8)
            Text(description)
                .font(.body)
                .foregroundColor(Color.appText)
                .padding(.top, 4)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
