import SwiftUI

struct TestView: View {
    var set: FlashcardSet
    @State private var shuffledCards: [Flashcard] = []
    @State private var userAnswers: [String] = []
    @State private var submitted = false
    @State private var score = 0
    @State private var mistakes: [Int] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(shuffledCards.enumerated()), id: \.offset) { idx, card in
                    VStack(alignment: .leading) {
                        Text("Q\(idx + 1): \(card.question)")
                            .font(.headline)
                        TextField("Your answer", text: Binding(
                            get: { userAnswers[idx] },
                            set: { userAnswers[idx] = $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                Button("Submit") {
                    score = 0
                    mistakes.removeAll()
                    for (index, card) in shuffledCards.enumerated() {
                        let given = userAnswers[index].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        let correct = card.answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        if given == correct {
                            score += 1
                        } else {
                            mistakes.append(index)
                        }
                    }
                    submitted = true
                }
                .padding(.vertical)
                if submitted {
                    Text("Score: \(score)/\(shuffledCards.count)")
                        .font(.headline)
                    ForEach(mistakes, id: \.self) { idx in
                        let card = shuffledCards[idx]
                        VStack(alignment: .leading) {
                            Text("Question: \(card.question)")
                            Text("Your answer: \(userAnswers[idx])")
                            Text("Correct answer: \(card.answer)")
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            shuffledCards = set.cards.shuffled()
            userAnswers = Array(repeating: "", count: shuffledCards.count)
        }
    }
}
