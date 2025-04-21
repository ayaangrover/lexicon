import SwiftUI
import FirebaseFirestore

struct EditSetView: View {
    var set: FlashcardSet
    @State private var cards: [Flashcard]
    @Environment(\.presentationMode) var presentationMode
    
    init(set: FlashcardSet) {
        self.set = set
        _cards = State(initialValue: set.cards)
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(cards.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Question", text: Binding(
                            get: { cards[index].question },
                            set: { cards[index].question = $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("Answer", text: Binding(
                            get: { cards[index].answer },
                            set: { cards[index].answer = $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Edit Cards")
            .background(Color.appBackground)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Color(red: 63/255, green: 183/255, blue: 154/255))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEdits()
                    }
                    .foregroundColor(Color(red: 63/255, green: 183/255, blue: 154/255))
                }
            }
        }
    }
    
    func saveEdits() {
        let db = Firestore.firestore()
        let updatedCards = cards.map { card in
            return [
                "question": card.question,
                "answer": card.answer,
                "questionAudio": card.questionAudio ?? "",
                "answerAudio": card.answerAudio ?? ""
            ]
        }
        db.collection("flashcardSets")
            .document(set.id)
            .updateData(["cards": updatedCards]) { error in
                presentationMode.wrappedValue.dismiss()
            }
    }
}
