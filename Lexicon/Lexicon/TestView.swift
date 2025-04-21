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
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Q\(idx + 1): \(card.question)")
                            .font(.headline)
                            .foregroundColor(.black)
                        TextField("Your answer", text: Binding(
                            get: { userAnswers[idx] },
                            set: { userAnswers[idx] = $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding()
                    .background(Color.appBackground)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
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
                .frame(maxWidth: .infinity)
                .background(Color(red: 63/255, green: 183/255, blue: 154/255))
                .foregroundColor(.appBackground)
                .cornerRadius(8)
                if submitted {
                    Text("Score: \(score)/\(shuffledCards.count)")
                        .font(.headline)
                        .foregroundColor(.black)
                    ForEach(mistakes, id: \.self) { idx in
                        let card = shuffledCards[idx]
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Question: \(card.question)")
                                .foregroundColor(.black)
                            Text("Your answer: \(userAnswers[idx])")
                                .foregroundColor(.red)
                            Text("Correct answer: \(card.answer)")
                                .foregroundColor(Color(red: 63/255, green: 183/255, blue: 154/255))
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding()
        }
        .background(Color.appBackground)
        .onAppear {
            shuffledCards = set.cards.shuffled()
            userAnswers = Array(repeating: "", count: shuffledCards.count)
        }
    }
}
