import Foundation

struct ChatMessage: Identifiable, Codable {
    var id: String = UUID().uuidString
    var text: String
    var isUser: Bool
    var timestamp: Date = Date()
}