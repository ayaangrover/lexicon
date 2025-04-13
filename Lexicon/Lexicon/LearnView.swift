import SwiftUI

enum LearnPhase {
    case multipleChoice
    case written
}

struct LearnView: View {
    var set: FlashcardSet
    @State private var mcPendingCards: [Flashcard] = []
    @State private var writtenPendingCards: [Flashcard] = []
    @State private var currentCard: Flashcard?
    @State private var answerInput = ""
    @State private var feedbackMessage = ""
    @State private var mcFeedbackMessage = ""
    @State private var currentPhase: LearnPhase = .multipleChoice
    @State private var showCongrats = false
    
    @State private var timeLeft = 30
    @State private var timer: Timer? = nil

    var body: some View {
        VStack(spacing: 20) {
            Text("Time Remaining: \(timeLeft)s")
                .font(.headline)
                .foregroundColor(timeLeft <= 5 ? .red : .black)
            if showCongrats {
                Text("Congrats! You got them all right!")
                    .font(.title)
                    .foregroundColor(.green)
            }
            else if let card = currentCard {
                Text(card.question)
                    .font(.largeTitle)
                
                if currentPhase == .multipleChoice {
                    if let options = multipleChoiceOptions(for: card) {
                        ForEach(options, id: \.self) { option in
                            Button(action: {
                                stopTimer()
                                checkMCAnswer(option, for: card)
                            }) {
                                Text(option)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    if !mcFeedbackMessage.isEmpty {
                        Text(mcFeedbackMessage)
                            .foregroundColor(.red)
                    }
                }
                else if currentPhase == .written {
                    TextField("Type your answer...", text: $answerInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    if !feedbackMessage.isEmpty {
                        Text(feedbackMessage)
                            .foregroundColor(.red)
                    }
                    Button(action: {
                        stopTimer()
                        checkWrittenAnswer()
                    }) {
                        HStack {
                            Image(systemName: "circle") 
                            Text("Submit Answer")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
            }
            else {
                Text("No flashcards available.")
            }
            Spacer()
        }
        .onAppear(perform: startLearning)
        .padding()
        .navigationTitle(set.title)
        .onChange(of: currentCard) { _ in
            resetAndStartTimer()
        }
    }
    
    
    func multipleChoiceOptions(for card: Flashcard) -> [String]? {
        let otherAnswers = set.cards
            .map { $0.answer }
            .filter { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() != card.answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        let randomAlternatives = Array(otherAnswers.shuffled().prefix(3))
        let options = randomAlternatives + [card.answer]
        return options.shuffled()
    }
    
    func checkMCAnswer(_ option: String, for card: Flashcard) {
        if option.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ==
            card.answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            mcFeedbackMessage = ""
            moveToNextMC()
        } else {
            mcFeedbackMessage = "Incorrect selection. Try again."
            resetAndStartTimer()
        }
    }
    
    func checkWrittenAnswer() {
        guard let card = currentCard else { return }
        if answerInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ==
            card.answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            moveToNextWritten()
        } else {
            feedbackMessage = "Incorrect. The correct answer was: \(card.answer)"
            writtenPendingCards.append(card)
            answerInput = ""
            resetAndStartTimer()
        }
    }
    
    func startLearning() {
        mcPendingCards = set.cards
        loadNextMCCard()
    }
    
    func loadNextMCCard() {
        stopTimer()
        if mcPendingCards.isEmpty {
            currentPhase = .written
            writtenPendingCards = set.cards
            loadNextWrittenCard()
        } else {
            currentCard = mcPendingCards.removeFirst()
            answerInput = ""
            feedbackMessage = ""
            mcFeedbackMessage = ""
        }
    }
    
    func moveToNextMC() {
        loadNextMCCard()
    }
    
    func loadNextWrittenCard() {
        stopTimer()
        if writtenPendingCards.isEmpty {
            showCongrats = true
            currentCard = nil
        } else {
            currentCard = writtenPendingCards.removeFirst()
            answerInput = ""
            feedbackMessage = ""
        }
    }
    
    func moveToNextWritten() {
        loadNextWrittenCard()
    }
    
    func resetAndStartTimer() {
        stopTimer()
        timeLeft = 30
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeLeft > 0 {
                timeLeft -= 1
            } else {
                stopTimer()
                if currentPhase == .written {
                    feedbackMessage = "Time expired. The correct answer was: \(currentCard?.answer ?? "")"
                    if let card = currentCard {
                        writtenPendingCards.append(card)
                    }
                    moveToNextWritten()
                } else {
                    mcFeedbackMessage = "Time expired. Moving to next question."
                    moveToNextMC()
                }
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
