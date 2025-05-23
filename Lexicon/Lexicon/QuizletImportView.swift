import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct QuizletImportView: View {
    @State private var quizletURL: String = ""
    @State private var message: String = ""
    @State private var isLoading: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Import Quizlet Set")
                    .font(.largeTitle)
                    .padding()

                TextField("Enter Quizlet URL", text: $quizletURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .padding(.horizontal)

                Button(action: importQuizletSet) {
                    Text(isLoading ? "Importing...Please wait" : "Import")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appIcon)
                        .foregroundColor(Color.appText)
                        .cornerRadius(10)
                }
                .disabled(isLoading || quizletURL.isEmpty)
                .padding(.horizontal)

                ScrollView {
                    Text(message)
                        .padding()
                        .font(.body)
                        .foregroundColor(.gray)
                }

                Spacer()
            }
            .navigationBarTitle("Quizlet Import", displayMode: .inline)
        }
    }

    func importQuizletSet() {
        guard let _ = URL(string: quizletURL) else {
            message = "Invalid URL."
            return
        }

        let pattern = #"quizlet\.com\/([0-9]+)"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let range = NSRange(quizletURL.startIndex..<quizletURL.endIndex, in: quizletURL)
            if let match = regex.firstMatch(in: quizletURL, options: [], range: range),
               let setIdRange = Range(match.range(at: 1), in: quizletURL) {
                let setId = String(quizletURL[setIdRange])

                let endpoint = "https://bold-shining-narwhal.ngrok-free.app/quizlet-set/\(setId)"
                guard let requestURL = URL(string: endpoint) else {
                    message = "Invalid endpoint URL."
                    return
                }

                var request = URLRequest(url: requestURL)
                request.addValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")

                isLoading = true
                message = ""

                URLSession.shared.dataTask(with: request) { data, response, error in
                    defer { DispatchQueue.main.async { isLoading = false } }

                    if let error = error {
                        DispatchQueue.main.async {
                            message = "Error: \(error.localizedDescription)"
                        }
                        return
                    }

                    guard let data = data else {
                        DispatchQueue.main.async {
                            message = "No data received."
                        }
                        return
                    }

                    if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
                       var jsonDictionary = jsonObject as? [String: Any] {

                        let creatorId = Auth.auth().currentUser?.uid ?? "unknown"
                        jsonDictionary["creatorId"] = creatorId
                        jsonDictionary["dateCreated"] = FieldValue.serverTimestamp()

                        let db = Firestore.firestore()
                        db.collection("flashcardSets").document(setId).setData(jsonDictionary) { err in
                            DispatchQueue.main.async {
                                if let err = err {
                                    message = "Error saving to Firestore: \(err.localizedDescription)"
                                } else {
                                    message = "Flashcards imported successfully!"
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            message = "Failed to parse JSON."
                        }
                    }
                }.resume()

            } else {
                message = "Unable to extract Quizlet set id."
            }
        } else {
            message = "Regex creation failed."
        }
    }
}
