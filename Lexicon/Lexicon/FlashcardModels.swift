// File: FlashcardModels.swift
import Foundation

struct Flashcard: Identifiable, Codable, Equatable, Hashable {
    var id = UUID()
    var question: String
    var answer: String
    var questionAudio: String?
    var answerAudio: String?
}

struct FlashcardSet: Identifiable, Hashable {
    var id: String
    var title: String
    var dateCreated: Date?
    var cards: [Flashcard]
}
