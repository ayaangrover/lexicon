// Swift
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MySetsView: View {
    @State private var sets: [FlashcardSet] = []

    var body: some View {
        List {
            ForEach(sets) { flashcardSet in
                NavigationLink(destination: SetDetailView(set: flashcardSet)) {
                    VStack(alignment: .leading) {
                        Text(flashcardSet.title)
                            .font(.headline)
                        if let date = flashcardSet.dateCreated {
                            Text(date, style: .date)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        deleteSet(id: flashcardSet.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .background(Color(UIColor.systemBackground))
        .navigationTitle("My Flashcard Sets")
        .onAppear(perform: fetchSets)
    }
    
    func fetchSets() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("flashcardSets")
            .whereField("creatorId", isEqualTo: uid)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching sets: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                self.sets = documents.compactMap { doc -> FlashcardSet? in
                    let data = doc.data()
                    guard let title = data["title"] as? String else { return nil }
                    var date: Date? = nil
                    if let timestamp = data["dateCreated"] as? Timestamp {
                        date = timestamp.dateValue()
                    }
                    var cards: [Flashcard] = []
                    if let cardsArray = data["cards"] as? [[String: Any]] {
                        for cardData in cardsArray {
                            if let question = cardData["question"] as? String,
                               let answer = cardData["answer"] as? String {
                                let questionAudio = cardData["questionAudio"] as? String
                                let answerAudio = cardData["answerAudio"] as? String
                                let flashcard = Flashcard(question: question, answer: answer, questionAudio: questionAudio, answerAudio: answerAudio)
                                cards.append(flashcard)
                            }
                        }
                    }
                    return FlashcardSet(id: doc.documentID, title: title, dateCreated: date, cards: cards)
                }
            }
    }

    func deleteSet(id: String) {
        let db = Firestore.firestore()
        db.collection("flashcardSets").document(id).delete { error in
            if let error = error {
                print("Error deleting set: \(error.localizedDescription)")
            }
        }
    }
}
