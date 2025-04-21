import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FlashcardGeneratorView: View {
    @State private var prompt: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    
    let groqEndpoint = "https://api.groq.com/openai/v1/chat/completions"
    let apiKey = "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"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Flashcard Generator")
                    .font(.largeTitle)
                    .padding()
                
                TextField("Enter your prompt", text: $prompt)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button(action: generateFlashcards) {
                    Text(isLoading ? "Generating..." : "Generate")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appIcon)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(isLoading || prompt.isEmpty)
                .padding(.horizontal)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationBarTitle("Flashcard Generator", displayMode: .inline)
        }
    }
    
    func generateFlashcards() {
        guard let url = URL(string: groqEndpoint) else { return }
        isLoading = true
        errorMessage = ""
        
        let flashcardTitle = prompt
        
        let messages: [[String: String]] = [
            [
                "role": "system",
                "content": "Your response must be a JSON object with keys \"cards\" containing an array of objects with \"question\" and \"answer\" as strings. Do not include any extra markdown or commentary."
            ],
            [
                "role": "user",
                "content": prompt
            ]
        ]
        
        let requestBody: [String: Any] = [
            "model": "llama3-70b-8192",
            "messages": messages
        ]
        
        guard let bodyData = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            isLoading = false
            errorMessage = "Failed to serialize request body."
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            defer {
                DispatchQueue.main.async { isLoading = false }
            }
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = "Error: \(error.localizedDescription)"
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    errorMessage = "No data received."
                }
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let messageDict = firstChoice["message"] as? [String: Any],
                   let content = messageDict["content"] as? String {
                    
                    let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                    var finalResponse: [String: Any]? = nil
                    
                    if let responseData = trimmedContent.data(using: .utf8),
                       let aiResponseJSON = try? JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] {
                        
                        if let cards = aiResponseJSON["cards"] as? [[String: Any]] {
                            let parsedCards = cards.compactMap { card -> [String: String]? in
                                if let question = card["question"] as? String {
                                    var answerStr = ""
                                    if let answer = card["answer"] as? String {
                                        answerStr = answer
                                    } else if let answerDict = card["answer"] as? [String: Any],
                                              let text = answerDict["text"] as? String {
                                        answerStr = text
                                    }
                                    return ["question": question, "answer": answerStr]
                                }
                                return nil
                            }
                            if !parsedCards.isEmpty {
                                finalResponse = ["cards": parsedCards]
                            }
                        }
                        if finalResponse == nil,
                           let question = aiResponseJSON["question"] as? String {
                            var answerStr = ""
                            if let answer = aiResponseJSON["answer"] as? String {
                                answerStr = answer
                            } else if let answerDict = aiResponseJSON["answer"] as? [String: Any],
                                      let text = answerDict["text"] as? String {
                                answerStr = text
                            }
                            finalResponse = ["cards": [["question": question, "answer": answerStr]]]
                        }
                    } else if trimmedContent.first == "\"" && trimmedContent.last == "\"" {
                        let stripped = String(trimmedContent.dropFirst().dropLast())
                        if let innerData = stripped.data(using: .utf8),
                           let innerJSON = try? JSONSerialization.jsonObject(with: innerData, options: []) as? [String: Any] {
                            if let question = innerJSON["question"] as? String {
                                var answerStr = ""
                                if let answer = innerJSON["answer"] as? String {
                                    answerStr = answer
                                } else if let answerDict = innerJSON["answer"] as? [String: Any],
                                          let text = answerDict["text"] as? String {
                                    answerStr = text
                                }
                                finalResponse = ["cards": [["question": question, "answer": answerStr]]]
                            }
                        }
                    }
                    
                    if let finalResponse = finalResponse {
                        saveSet(with: finalResponse, title: flashcardTitle)
                    } else {
                        saveSet(with: ["raw": trimmedContent], title: flashcardTitle)
                    }
                    DispatchQueue.main.async { prompt = "" }
                } else {
                    DispatchQueue.main.async { errorMessage = "Failed to parse response." }
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "JSON Error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func saveSet(with result: [String: Any], title: String) {
        let db = Firestore.firestore()
        var setData: [String: Any] = [
            "title": title,
            "dateCreated": FieldValue.serverTimestamp(),
            "creatorId": Auth.auth().currentUser?.uid ?? "unknown"
        ]
        
        if let cards = result["cards"] {
            setData["cards"] = cards
        } else if let raw = result["raw"] {
            setData["raw"] = raw
        }
        
        db.collection("flashcardSets").addDocument(data: setData) { error in
            if let error = error {
                print("Error saving to Firestore: \(error.localizedDescription)")
            } else {
                print("Flashcards saved successfully!")
            }
        }
    }
}

struct FlashcardGeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        FlashcardGeneratorView()
    }
}
