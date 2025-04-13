import SwiftUI
import AVFoundation

struct FlashcardView: View {
    var card: Flashcard
    @State private var flipped = false
    @State private var flipDegrees = 0.0

    let synthesizer = AVSpeechSynthesizer()

    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .frame(height: 250)
                    .shadow(radius: 5)
                Text(flipped ? card.answer : card.question)
                    .font(.title2)
                    .foregroundColor(.black)
                    .padding()
                    .scaleEffect(x: 1, y: flipped ? -1 : 1)
            }
            .onTapGesture {
                withAnimation(Animation.spring()) {
                    flipDegrees += 180
                    flipped.toggle()
                }
            }
            .rotation3DEffect(.degrees(flipDegrees), axis: (x: 1, y: 0, z: 0))
            
            Button("Speak Flashcard") {
                speakText(flipped ? card.answer : card.question)
            }
            .padding()
            .cornerRadius(8)
        }
    }
    
    func speakText(_ textToSpeak: String) {
        let utterance = AVSpeechUtterance(string: textToSpeak)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }
}
