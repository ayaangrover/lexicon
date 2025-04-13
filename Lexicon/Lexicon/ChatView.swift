import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ChatView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var messages: [ChatMessage] = []
    @State private var newMessage: String = ""
    @State private var availableSets: [FlashcardSet] = []
    @State private var selectedSet: FlashcardSet? = nil
    @State private var isLoading: Bool = false

    let apiKey = "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"

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Picker("Choose Vocabulary Set", selection: $selectedSet) {
                        Text("None").tag(FlashcardSet?.none)
                        ForEach(availableSets, id: \.id) { set in
                            Text(set.title).tag(Optional(set))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: 200, alignment: .leading)
                    Spacer()
                }
                .padding([.leading, .top])

                List(availableSets, id: \.id) { set in
                    Text(set.title)
                }
                .hidden() 
                .onAppear {
                    fetchAvailableSets()
                }

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(messages) { msg in
                            HStack {
                                if msg.isUser {
                                    Spacer()
                                    Text(.init(msg.text)) 
                                        .padding()
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(8)
                                } else {
                                    Text(.init(msg.text)) 
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(8)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: .infinity)

                HStack {
                    TextField("Type message...", text: $newMessage)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Send") {
                        sendMessage()
                    }
                    .disabled(newMessage.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                }
                .padding()
            }
            .navigationBarTitle("AI Chat", displayMode: .inline)
            .navigationBarItems(trailing: Button("Clear Chat") {
                clearChat()
            })
        }
    }
    
    func fetchAvailableSets() {
        guard let uid = Auth.auth().currentUser?.uid,
              let email = Auth.auth().currentUser?.email else { return }
        let db = Firestore.firestore()
        
        let ownedQuery = db.collection("flashcardSets")
            .whereField("creatorId", isEqualTo: uid)
        let sharedQuery = db.collection("flashcardSets")
            .whereField("sharedWith", arrayContains: email)
        
        var allSets: [FlashcardSet] = []
        let group = DispatchGroup()
        
        group.enter()
        ownedQuery.getDocuments { snapshot, error in
            defer { group.leave() }
            if let documents = snapshot?.documents {
                let ownerSets = documents.compactMap { doc -> FlashcardSet? in
                    let data = doc.data()
                    guard let title = data["title"] as? String else { return nil }
                    var date: Date? = nil
                    if let timestamp = data["dateCreated"] as? Timestamp {
                        date = timestamp.dateValue()
                    }
                    var cards: [Flashcard] = []
                    if let cardsArray = data["cards"] as? [[String: Any]] {
                        for cardData in cardsArray {
                            if let question = cardData["question"] as? String,
                               let answer = cardData["answer"] as? String {
                                let qAudio = cardData["questionAudio"] as? String
                                let aAudio = cardData["answerAudio"] as? String
                                cards.append(Flashcard(question: question, answer: answer, questionAudio: qAudio, answerAudio: aAudio))
                            }
                        }
                    }
                    return FlashcardSet(id: doc.documentID, title: title, dateCreated: date, cards: cards)
                }
                allSets.append(contentsOf: ownerSets)
            }
        }
        
        group.enter()
        sharedQuery.getDocuments { snapshot, error in
            defer { group.leave() }
            if let documents = snapshot?.documents {
                let sharedSets = documents.compactMap { doc -> FlashcardSet? in
                    let data = doc.data()
                    guard let title = data["title"] as? String else { return nil }
                    var date: Date? = nil
                    if let timestamp = data["dateCreated"] as? Timestamp {
                        date = timestamp.dateValue()
                    }
                    var cards: [Flashcard] = []
                    if let cardsArray = data["cards"] as? [[String: Any]] {
                        for cardData in cardsArray {
                            if let question = cardData["question"] as? String,
                               let answer = cardData["answer"] as? String {
                                let qAudio = cardData["questionAudio"] as? String
                                let aAudio = cardData["answerAudio"] as? String
                                cards.append(Flashcard(question: question, answer: answer, questionAudio: qAudio, answerAudio: aAudio))
                            }
                        }
                    }
                    return FlashcardSet(id: doc.documentID, title: title, dateCreated: date, cards: cards)
                }
                allSets.append(contentsOf: sharedSets)
            }
        }
        
        group.notify(queue: .main) {
            var unique = [String: FlashcardSet]()
            allSets.forEach { unique[$0.id] = $0 }
            self.availableSets = Array(unique.values)
        }
    }
    
    func checkUserExaUsage(completion: @escaping (Double) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(0.0)
            return
        }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data(), let usage = data["exaUsageTotal"] as? Double {
                completion(usage)
            } else {
                completion(0.0)
            }
        }
    }

    func updateUserExaUsage(by amount: Double) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        userRef.updateData(["exaUsageTotal": FieldValue.increment(amount)])
    }

    func callExaAPI(for prompt: String, completion: @escaping (String, Double, [[String: Any]]) -> Void) {
        guard let exaURL = URL(string: "https://api.exa.ai/chat/completions") else {
            completion("exa.ai endpoint error", 0.0, [])
            return
        }
        var exaRequest = URLRequest(url: exaURL)
        exaRequest.httpMethod = "POST"
        exaRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        exaRequest.addValue("Bearer 263dca21-9f1a-4418-bb00-751e8066d9f3", forHTTPHeaderField: "Authorization")
        
        let exaBody: [String: Any] = [
            "model": "exa",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "extra_body": ["text": false]
        ]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: exaBody, options: []) else {
            completion("Request data error", 0.0, [])
            return
        }
        exaRequest.httpBody = bodyData

        URLSession.shared.dataTask(with: exaRequest) { data, response, error in
            if let error = error {
                completion("exa.ai error: \(error.localizedDescription)", 0.0, [])
                return
            }
            guard let data = data else {
                completion("exa.ai: no data", 0.0, [])
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let answer = json["answer"] as? String,
                   let costDict = json["costDollars"] as? [String: Any],
                   let cost = costDict["total"] as? Double,
                   let citations = json["citations"] as? [[String: Any]] {
                    completion(answer, cost, citations)
                } else {
                    let responseStr = String(data: data, encoding: .utf8) ?? "No readable response"
                    completion("Failed to parse response: \(responseStr)", 0.0, [])
                }
            } catch {
                completion("JSON parsing error: \(error.localizedDescription)", 0.0, [])
            }
        }.resume()
    }

    func sendMessage() {
        let trimmed = newMessage.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isLoading = true

        let userMsg = ChatMessage(text: trimmed, isUser: true)
        messages.append(userMsg)
        newMessage = ""

        var chatHistory: [[String: String]] = []
        
        var systemInstruction = "I am the system. You are a pro vocabulary teacher. Only answer questions about the provided vocabulary. If needed, use additional context provided."
        if let vocabSet = selectedSet, !vocabSet.cards.isEmpty {
            let vocabList = vocabSet.cards.map { "Term: \($0.question) - Definition: \($0.answer)" }
            systemInstruction += " Vocabulary: " + vocabList.joined(separator: " | ")
            print(systemInstruction)
        } else {
            systemInstruction += " (Please choose a vocabulary set for context.)"
        }
        
        callExaAPI(for: trimmed) { exaReply, cost, citations in
            let extraContext = "\nAdditional Info: " + exaReply
            let finalSystemInstruction = systemInstruction + extraContext

            chatHistory.append(["role": "system", "content": finalSystemInstruction])
            for message in messages {
                let role = message.isUser ? "user" : "assistant"
                chatHistory.append(["role": role, "content": message.text])
            }
            
            let groqRequestBody: [String: Any] = [
                "messages": chatHistory,
                "model": "llama3-8b-8192"
            ]
            
            guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions"),
                  let groqBodyData = try? JSONSerialization.data(withJSONObject: groqRequestBody, options: []) else {
                DispatchQueue.main.async {
                    isLoading = false
                }
                return
            }
            
            var groqRequest = URLRequest(url: url)
            groqRequest.httpMethod = "POST"
            groqRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            groqRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            groqRequest.httpBody = groqBodyData
            
            URLSession.shared.dataTask(with: groqRequest) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        messages.append(ChatMessage(text: "Error: \(error.localizedDescription)", isUser: false))
                        isLoading = false
                    }
                    return
                }
                
                guard let data = data else {
                    DispatchQueue.main.async {
                        messages.append(ChatMessage(text: "No data received from API.", isUser: false))
                        isLoading = false
                    }
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let msgDict = firstChoice["message"] as? [String: Any],
                       let groqReply = msgDict["content"] as? String {
                        DispatchQueue.main.async {
                            messages.append(ChatMessage(text: groqReply, isUser: false))
                            isLoading = false
                            saveChatToFirestore()
                        }
                    } else {
                        let responseStr = String(data: data, encoding: .utf8) ?? "No readable response"
                        DispatchQueue.main.async {
                            messages.append(ChatMessage(text: "Failed to parse response: \(responseStr)", isUser: false))
                            isLoading = false
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        messages.append(ChatMessage(text: "Failed to parse JSON: \(error.localizedDescription)", isUser: false))
                        isLoading = false
                    }
                }
            }.resume()
        }
    }
    
    func clearChat() {
        messages.removeAll()
        saveChatToFirestore(clear: true)
    }
    
    func saveChatToFirestore(clear: Bool = false) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let chatData: [String: Any] = [
            "messages": clear ? [] : messages.map { [
                "text": $0.text,
                "isUser": $0.isUser,
                "timestamp": $0.timestamp
            ] },
            "lastUpdated": Timestamp(date: Date())
        ]
        db.collection("chats").document(uid).setData(chatData, merge: true)
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}
