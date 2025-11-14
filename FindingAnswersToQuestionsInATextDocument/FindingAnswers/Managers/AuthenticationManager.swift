/*
StudyPal AI - Authentication Manager

Abstract:
Manages user authentication, session, and user data.
*/

import Foundation
import SwiftUI

class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    
    private let userDefaultsKey = "studypal_current_user"
    
    private init() {
        loadUser()
    }
    
    // MARK: - Authentication Methods
    
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            // For demo purposes, accept any email/password
            let user = User(
                name: email.components(separatedBy: "@").first?.capitalized ?? "User",
                email: email,
                badges: [Badge.availableBadges[4]] // Early Adopter badge
            )
            
            self.currentUser = user
            self.isAuthenticated = true
            self.isLoading = false
            self.saveUser(user)
            
            completion(.success(user))
        }
    }
    
    func register(name: String, email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            let user = User(
                name: name,
                email: email,
                badges: [Badge.availableBadges[4]] // Early Adopter badge
            )
            
            self.currentUser = user
            self.isAuthenticated = true
            self.isLoading = false
            self.saveUser(user)
            
            completion(.success(user))
        }
    }
    
    func signInWithApple(completion: @escaping (Result<User, Error>) -> Void) {
        isLoading = true
        
        // Simulate Apple Sign In
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            let user = User(
                name: "Apple User",
                email: "user@appleid.com",
                badges: [Badge.availableBadges[4]]
            )
            
            self.currentUser = user
            self.isAuthenticated = true
            self.isLoading = false
            self.saveUser(user)
            
            completion(.success(user))
        }
    }
    
    func signInWithGoogle(completion: @escaping (Result<User, Error>) -> Void) {
        isLoading = true
        
        // Simulate Google Sign In
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            let user = User(
                name: "Google User",
                email: "user@gmail.com",
                badges: [Badge.availableBadges[4]]
            )
            
            self.currentUser = user
            self.isAuthenticated = true
            self.isLoading = false
            self.saveUser(user)
            
            completion(.success(user))
        }
    }
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
    
    // MARK: - User Data Management
    
    func updateUser(_ user: User) {
        currentUser = user
        saveUser(user)
    }
    
    func incrementDocumentCount() {
        guard var user = currentUser else { return }
        user.totalDocuments += 1
        checkAndAwardBadges(for: &user)
        updateUser(user)
    }
    
    func incrementQuestionCount() {
        guard var user = currentUser else { return }
        user.totalQuestions += 1
        checkAndAwardBadges(for: &user)
        updateUser(user)
    }
    
    func incrementFlashcardCount() {
        guard var user = currentUser else { return }
        user.totalFlashcards += 1
        checkAndAwardBadges(for: &user)
        updateUser(user)
    }
    
    func updateStreak() {
        guard var user = currentUser else { return }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastActive = calendar.startOfDay(for: user.lastActiveDate)
        
        if let daysDiff = calendar.dateComponents([.day], from: lastActive, to: today).day {
            if daysDiff == 0 {
                // Same day, streak already counted
                return
            } else if daysDiff == 1 {
                // Consecutive day
                user.learningStreak += 1
            } else if daysDiff > 1 {
                // Streak broken, restart
                user.learningStreak = 1
            }
        }
        
        // If this is the first activity (streak was 0), set to 1
        if user.learningStreak == 0 {
            user.learningStreak = 1
        }
        
        user.lastActiveDate = Date()
        checkAndAwardBadges(for: &user)
        updateUser(user)
    }
    
    // MARK: - Badge System
    
    private func checkAndAwardBadges(for user: inout User) {
        // Curious Learner - 10+ questions
        if user.totalQuestions >= 10 && !user.badges.contains(where: { $0.name == "Curious Learner" }) {
            user.badges.append(Badge.availableBadges[0])
        }
        
        // Research Pro - 10 documents
        if user.totalDocuments >= 10 && !user.badges.contains(where: { $0.name == "Research Pro" }) {
            user.badges.append(Badge.availableBadges[1])
        }
        
        // Study Streak - 7 days
        if user.learningStreak >= 7 && !user.badges.contains(where: { $0.name == "Study Streak" }) {
            user.badges.append(Badge.availableBadges[2])
        }
        
        // Knowledge Master - 50+ flashcards
        if user.totalFlashcards >= 50 && !user.badges.contains(where: { $0.name == "Knowledge Master" }) {
            user.badges.append(Badge.availableBadges[3])
        }
    }
    
    // MARK: - Persistence
    
    private func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadUser() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = user
            isAuthenticated = true
        }
    }
}
