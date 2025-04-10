import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ManualFlashcardCreatorView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var setTitle: String = ""
    @State private var question: String = ""
    @State private var answer: String = ""
    @State private var flashcards: [Flashcard] = []
    @State private var errorMessage: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Set Details")) {
                        TextField("Set Title", text: $setTitle)
                    }
                    
                    Section(header: Text("Add Flashcard")) {
                        TextField("Question", text: $question)
                        TextField("Answer", text: $answer)
                        Button("Add Flashcard") {
                            addFlashcard()
                        }
                    }
                    
                    if !flashcards.isEmpty {
                        Section(header: Text("Flashcards Added")) {
                            ForEach(flashcards) { card in
                                VStack(alignment: .leading) {
                                    Text(card.question)
                                        .font(.headline)
                                    Text(card.answer)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                HStack {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding()
                    
                    Spacer()
                    
                    Button("Save Set") {
                        saveSet()
                    }
                    .padding()
                    .disabled(setTitle.trimmingCharacters(in: .whitespaces).isEmpty || flashcards.isEmpty)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Manual Flashcard Set")
        }
    }
    
    func addFlashcard() {
        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAnswer = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuestion.isEmpty, !trimmedAnswer.isEmpty else {
            errorMessage = "Both question and answer must be provided."
            return
        }
        errorMessage = ""
        let newFlashcard = Flashcard(question: trimmedQuestion, answer: trimmedAnswer, questionAudio: nil, answerAudio: nil)
        flashcards.append(newFlashcard)
        question = ""
        answer = ""
    }
    
    func saveSet() {
        let db = Firestore.firestore()
        let setData: [String: Any] = [
            "title": setTitle,
            "dateCreated": FieldValue.serverTimestamp(),
            "cards": flashcards.map { card in
                return [
                    "question": card.question,
                    "answer": card.answer,
                    "questionAudio": card.questionAudio ?? "",
                    "answerAudio": card.answerAudio ?? ""
                ]
            },
            "creatorId": Auth.auth().currentUser?.uid ?? "unknown"
        ]
        
        // Using the title as the document id may lead to issues so a generated id or UUID is recommended.
        db.collection("flashcardSets").addDocument(data: setData) { error in
            if let error = error {
                errorMessage = "Error saving set: \(error.localizedDescription)"
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
