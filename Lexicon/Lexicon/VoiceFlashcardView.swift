import SwiftUI
import AVFoundation

struct VoiceFlashcardView: View {
    var textToSpeak: String
    let synthesizer = AVSpeechSynthesizer()

    var body: some View {
        Button("Speak Flashcard") {
            speakText()
        }
        .padding()
        .background(Color.blue.opacity(0.2))
        .cornerRadius(8)
    }

    func speakText() {
        let utterance = AVSpeechUtterance(string: textToSpeak)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }
}

