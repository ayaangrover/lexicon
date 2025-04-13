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
        guard let uid = Auth.auth().currentUser?.uid,
              let email = Auth.auth().currentUser?.email else { return }
        let db = Firestore.firestore()
        
        let ownedQuery = db.collection("flashcardSets")
            .whereField("creatorId", isEqualTo: uid)
        
        let sharedQuery = db.collection("flashcardSets")
            .whereField("sharedWith", arrayContains: email)
        
        var allSets: [FlashcardSet] = []
        let group = DispatchGroup()
        
        group.enter()
        ownedQuery.getDocuments { snapshot, error in
            defer { group.leave() }
            if let documents = snapshot?.documents {
                let ownedSets = documents.compactMap { doc -> FlashcardSet? in
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
                allSets.append(contentsOf: ownedSets)
            }
        }
        
        group.enter()
        sharedQuery.getDocuments { snapshot, error in
            defer { group.leave() }
            if let documents = snapshot?.documents {
                let sharedSets = documents.compactMap { doc -> FlashcardSet? in
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
                allSets.append(contentsOf: sharedSets)
            }
        }
        
        group.notify(queue: .main) {
            var uniqueSetsDict = [String: FlashcardSet]()
            for set in allSets {
                uniqueSetsDict[set.id] = set
            }
            self.sets = Array(uniqueSetsDict.values)
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
