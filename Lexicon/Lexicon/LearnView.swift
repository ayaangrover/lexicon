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
    @State private var currentOptions: [String] = []
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
                .foregroundColor(timeLeft <= 5 ? .red : .appText)
            if showCongrats {
                Text("Congrats! You got them all right!")
                    .font(.title)
                    .foregroundColor(Color(red: 63/255, green: 183/255, blue: 154/255))
            }
            else if let card = currentCard {
                Text(card.question)
                    .font(.largeTitle)
                    .foregroundColor(.appText)
                    .multilineTextAlignment(.center)
                    .padding()
                
                if currentPhase == .multipleChoice {
                    ForEach(currentOptions, id: \.self) { option in
                        Button {
                            stopTimer()
                            checkMCAnswer(option, for: card)
                        } label: {
                            Text(option)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 63/255, green: 183/255, blue: 154/255))
                                .foregroundColor(.white)
                                .cornerRadius(8)
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
                    Button {
                        stopTimer()
                        checkWrittenAnswer()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Submit Answer")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 63/255, green: 183/255, blue: 154/255))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
            }
            else {
                Text("No flashcards available.")
                    .foregroundColor(.appText)
            }
            Spacer()
        }
        .padding()
        .navigationTitle(set.title)
        .onAppear(perform: startLearning)
        .onChange(of: currentCard) { _ in
            if currentPhase == .multipleChoice {
                setupCurrentOptions()
            }
            resetAndStartTimer()
        }
    }
    
    func setupCurrentOptions() {
        if let card = currentCard, currentPhase == .multipleChoice {
            let otherAnswers = set.cards.map { $0.answer }
                .filter { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() != card.answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            let randomAlternatives = Array(otherAnswers.shuffled().prefix(3))
            currentOptions = (randomAlternatives + [card.answer]).shuffled()
        }
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
        mcPendingCards = set.cards.shuffled()
        loadNextMCCard()
    }
    
    func loadNextMCCard() {
        stopTimer()
        if mcPendingCards.isEmpty {
            currentPhase = .written
            writtenPendingCards = set.cards.shuffled()
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
