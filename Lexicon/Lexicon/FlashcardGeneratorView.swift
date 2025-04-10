import SwiftUI
import UniformTypeIdentifiers

struct FlashcardGeneratorView: View {
    @State private var inputText: String = ""
    @State private var selectedPDF: URL?
    @State private var generatedFlashcards: [(String, String)] = []
    @State private var isGenerating: Bool = false
    @State private var showDocumentPicker: Bool = false
    @State private var generationError: String = ""
    
    let apiKey = "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"
    let endpoint = "https://api.groq.com/openai/v1/chat/completions"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("AI Flashcard Generator")
                .font(.largeTitle)
                .fontWeight(.bold)
            TextField("Enter a topic or paste text here...", text: $inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Button("Upload PDF") {
                showDocumentPicker = true
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            Button(action: generateFlashcards) {
                Text(isGenerating ? "Generating..." : "Generate Flashcards")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(isGenerating || (inputText.isEmpty && selectedPDF == nil))
            .padding()
            if !generationError.isEmpty {
                Text(generationError)
                    .foregroundColor(.red)
                    .padding()
            }
            List(generatedFlashcards, id: \.0) { flashcard in
                VStack(alignment: .leading) {
                    Text(flashcard.0)
                        .font(.headline)
                    Text(flashcard.1)
                        .font(.body)
                        .foregroundColor(.gray)
                }
                .padding()
            }
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(selectedPDF: $selectedPDF)
        }
    }
    
    func generateFlashcards() {
        isGenerating = true
        generationError = ""
        let systemMessage = "You are an AI flashcard generator. Given the user input, generate flashcards as a JSON array where each flashcard is an object with 'question' and 'answer' keys. Output valid JSON only."
        let userMessage = inputText
        
        let requestBody: [String: Any] = [
            "model": "llama3-8b-8192",
            "messages": [
                ["role": "system", "content": systemMessage],
                ["role": "user", "content": userMessage]
            ]
        ]
        
        guard let url = URL(string: endpoint),
              let bodyData = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            generationError = "Failed to construct request."
            isGenerating = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            defer {
                DispatchQueue.main.async {
                    self.isGenerating = false
                }
            }
            if let error = error {
                DispatchQueue.main.async {
                    self.generationError = "Network error: \(error.localizedDescription)"
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    self.generationError = "No data received from the server."
                }
                return
            }
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = jsonResponse["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let messageDict = firstChoice["message"] as? [String: Any],
                   let replyContent = messageDict["content"] as? String {
                    DispatchQueue.main.async {
                        // Output full reply as a single flashcard entry
                        self.generatedFlashcards = [("Full Response", replyContent)]
                    }
                } else {
                    let responseStr = String(data: data, encoding: .utf8) ?? "No readable response"
                    DispatchQueue.main.async {
                        self.generationError = "Failed to parse response: \(responseStr)"
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.generationError = "JSON parsing error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}
