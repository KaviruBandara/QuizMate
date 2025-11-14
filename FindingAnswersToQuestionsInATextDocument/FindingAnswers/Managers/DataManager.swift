/*
StudyPal AI - Data Manager

Abstract:
Central data management for documents, flashcards, and user statistics.
*/

import Foundation
import SwiftUI

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var documents: [Document] = []
    @Published var flashcards: [Flashcard] = []
    
    private let documentsKey = "studypal_documents"
    private let flashcardsKey = "studypal_flashcards"
    
    private init() {
        loadData()
        // Add sample document and flashcards for testing
        if documents.isEmpty {
            let sampleDoc = Document(title: "Fox & Dog", body: "The quick brown fox jumps over the lethargic dog.")
            documents = [sampleDoc]
            saveDocuments()
            
            // Add sample flashcards
            if flashcards.isEmpty {
                flashcards = [
                    Flashcard(documentId: sampleDoc.id.uuidString, question: "What color is the fox?", answer: "Brown"),
                    Flashcard(documentId: sampleDoc.id.uuidString, question: "What does the fox do?", answer: "Jumps over the dog"),
                    Flashcard(documentId: sampleDoc.id.uuidString, question: "What animal does the fox jump over?", answer: "The dog")
                ]
                saveFlashcards()
            }
        }
    }
    
    // MARK: - Document Management
    
    func addDocument(_ document: Document) {
        var newDoc = document
        newDoc.userId = AuthenticationManager.shared.currentUser?.id
        documents.insert(newDoc, at: 0)
        saveDocuments()
        AuthenticationManager.shared.incrementDocumentCount()
        AuthenticationManager.shared.updateStreak()
    }
    
    func updateDocument(_ document: Document) {
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            documents[index] = document
            saveDocuments()
        }
    }
    
    func deleteDocument(_ document: Document) {
        documents.removeAll { $0.id == document.id }
        // Also delete associated flashcards
        flashcards.removeAll { $0.documentId == document.id.uuidString }
        saveDocuments()
        saveFlashcards()
    }
    
    func toggleFavorite(_ document: Document) {
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            documents[index].isFavorite.toggle()
            saveDocuments()
        }
    }
    
    // MARK: - Flashcard Management
    
    func createFlashcard(documentId: String, question: String, answer: String) {
        // Extract main concept from question and answer
        let enhancedQuestion = extractMainConcept(from: question)
        let enhancedAnswer = formatAnswer(answer, for: enhancedQuestion)
        
        let flashcard = Flashcard(
            documentId: documentId,
            question: enhancedQuestion,
            answer: enhancedAnswer
        )
        flashcards.append(flashcard)
        saveFlashcards()
        
        // Update document flashcard count
        if let index = documents.firstIndex(where: { $0.id.uuidString == documentId }) {
            documents[index].flashcardCount += 1
            saveDocuments()
        }
        
        AuthenticationManager.shared.incrementFlashcardCount()
    }
    
    func updateFlashcard(_ flashcard: Flashcard) {
        if let index = flashcards.firstIndex(where: { $0.id == flashcard.id }) {
            flashcards[index] = flashcard
            saveFlashcards()
        }
    }
    
    func deleteFlashcard(_ flashcard: Flashcard) {
        flashcards.removeAll { $0.id == flashcard.id }
        saveFlashcards()
        
        // Update document flashcard count
        if let index = documents.firstIndex(where: { $0.id.uuidString == flashcard.documentId }) {
            documents[index].flashcardCount = max(0, documents[index].flashcardCount - 1)
            saveDocuments()
        }
    }
    
    func getFlashcards(for documentId: String) -> [Flashcard] {
        return flashcards.filter { $0.documentId == documentId }
    }
    
    func getFlashcardSets() -> [FlashcardSet] {
        let groupedFlashcards = Dictionary(grouping: flashcards) { $0.documentId }
        
        return groupedFlashcards.compactMap { documentId, cards in
            guard let document = documents.first(where: { $0.id.uuidString == documentId }) else {
                return nil
            }
            return FlashcardSet(id: documentId, documentTitle: document.title, flashcards: cards)
        }
    }
    
    // MARK: - Statistics
    
    func incrementQuestionCount(for documentId: UUID) {
        if let index = documents.firstIndex(where: { $0.id == documentId }) {
            documents[index].questionCount += 1
            saveDocuments()
        }
        AuthenticationManager.shared.incrementQuestionCount()
        AuthenticationManager.shared.updateStreak()
    }
    
    // MARK: - Flashcard Enhancement
    
    private func extractMainConcept(from question: String) -> String {
        // Remove common question words and extract the core concept
        let questionWords = ["what", "who", "where", "when", "why", "how", "is", "are", "was", "were", "does", "do", "did", "can", "could", "would", "should"]
        
        var words = question.lowercased()
            .replacingOccurrences(of: "?", with: "")
            .components(separatedBy: " ")
            .filter { !questionWords.contains($0) && $0.count > 2 }
        
        // If question is too short, return as is
        if words.count < 2 {
            return question
        }
        
        // Create a concept-focused question
        let mainWords = words.prefix(4).joined(separator: " ")
        
        // Determine question type and format accordingly
        let lowerQuestion = question.lowercased()
        if lowerQuestion.hasPrefix("what is") || lowerQuestion.hasPrefix("what are") {
            return "What is \(mainWords)?"
        } else if lowerQuestion.hasPrefix("who") {
            return "Who \(mainWords)?"
        } else if lowerQuestion.hasPrefix("where") {
            return "Where \(mainWords)?"
        } else if lowerQuestion.hasPrefix("when") {
            return "When \(mainWords)?"
        } else if lowerQuestion.hasPrefix("why") {
            return "Why \(mainWords)?"
        } else if lowerQuestion.hasPrefix("how") {
            return "How \(mainWords)?"
        }
        
        // Default: capitalize first letter and ensure question mark
        let formatted = mainWords.prefix(1).capitalized + mainWords.dropFirst()
        return formatted.hasSuffix("?") ? formatted : formatted + "?"
    }
    
    private func formatAnswer(_ answer: String, for question: String) -> String {
        // Clean up the answer
        var cleanAnswer = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If answer is too long (more than 100 chars), try to extract key information
        if cleanAnswer.count > 100 {
            // Split into sentences
            let sentences = cleanAnswer.components(separatedBy: CharacterSet(charactersIn: ".!?"))
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            
            // Take first 1-2 sentences that contain relevant info
            if let firstSentence = sentences.first {
                cleanAnswer = firstSentence
                if cleanAnswer.count < 50, sentences.count > 1 {
                    cleanAnswer += ". " + sentences[1]
                }
                if !cleanAnswer.hasSuffix(".") && !cleanAnswer.hasSuffix("!") {
                    cleanAnswer += "."
                }
            }
        }
        
        // Ensure proper capitalization
        if !cleanAnswer.isEmpty {
            cleanAnswer = cleanAnswer.prefix(1).uppercased() + cleanAnswer.dropFirst()
        }
        
        return cleanAnswer
    }
    
    // MARK: - Persistence
    
    private func saveDocuments() {
        do {
            let encoded = try JSONEncoder().encode(documents)
            UserDefaults.standard.set(encoded, forKey: documentsKey)
            UserDefaults.standard.synchronize()
            print("✅ Successfully saved \(documents.count) documents")
        } catch {
            print("❌ Error saving documents: \(error.localizedDescription)")
        }
    }
    
    private func saveFlashcards() {
        do {
            let encoded = try JSONEncoder().encode(flashcards)
            UserDefaults.standard.set(encoded, forKey: flashcardsKey)
            UserDefaults.standard.synchronize()
            print("✅ Successfully saved \(flashcards.count) flashcards")
        } catch {
            print("❌ Error saving flashcards: \(error.localizedDescription)")
        }
    }
    
    private func loadData() {
        // Load documents
        if let data = UserDefaults.standard.data(forKey: documentsKey) {
            do {
                let decoded = try JSONDecoder().decode([Document].self, from: data)
                documents = decoded
                print("✅ Successfully loaded \(documents.count) documents")
            } catch {
                print("❌ Error loading documents: \(error.localizedDescription)")
            }
        } else {
            print("ℹ️ No documents data found in UserDefaults")
        }
        
        // Load flashcards
        if let data = UserDefaults.standard.data(forKey: flashcardsKey) {
            do {
                let decoded = try JSONDecoder().decode([Flashcard].self, from: data)
                flashcards = decoded
                print("✅ Successfully loaded \(flashcards.count) flashcards")
            } catch {
                print("❌ Error loading flashcards: \(error.localizedDescription)")
            }
        } else {
            print("ℹ️ No flashcards data found in UserDefaults")
        }
    }
}
