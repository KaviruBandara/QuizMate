/*
QuizMate - Main App Entry Point

Abstract:
Main app coordinator with authentication flow and tab-based navigation.
*/

import SwiftUI

@main
struct StudyPalApp: App {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var dataManager = DataManager.shared
    @AppStorage("appTheme") private var appTheme: String = "auto"
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
                    .environmentObject(dataManager)
                    .preferredColorScheme(colorScheme)
            } else {
                LoginView()
                    .environmentObject(authManager)
                    .preferredColorScheme(colorScheme)
            }
        }
    }
    
    private var colorScheme: ColorScheme? {
        switch appTheme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil // Auto (system)
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        TabView {
            // Dashboard Tab
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
            
            // Documents Tab
            EnhancedDocumentsView()
                .tabItem {
                    Label("Documents", systemImage: "doc.text.fill")
                }
            
            // Flashcards Tab
            FlashcardsTabView()
                .tabItem {
                    Label("Flashcards", systemImage: "rectangle.portrait.on.rectangle.portrait.fill")
                }
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .accentColor(.blue)
    }
}

// Enhanced Documents View with DataManager integration
struct EnhancedDocumentsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddDocument = false
    @State private var showingCamera = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(UIColor.systemBackground),
                        Color(UIColor.secondarySystemBackground)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if dataManager.documents.isEmpty {
                    emptyStateView
                } else {
                    documentsListView
                }
            }
            .navigationTitle("Documents")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingAddDocument = true }) {
                            Label("New Document", systemImage: "doc.badge.plus")
                        }
                        Button(action: { showingCamera = true }) {
                            Label("Scan with Camera", systemImage: "camera.fill")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddDocument) {
                AddDocumentView()
                    .environmentObject(dataManager)
            }
            .sheet(isPresented: $showingCamera) {
                CameraView()
                    .environmentObject(dataManager)
            }
            
            WelcomeView()
        }
        .navigationViewStyle(.automatic)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 80))
                .foregroundColor(.blue.opacity(0.6))
            
            Text("No Documents Yet")
                .font(.title.bold())
                .foregroundColor(.primary)
            
            Text("Create a document or scan one with your camera to get started")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                Button(action: { showingAddDocument = true }) {
                    Label("New Document", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                Button(action: { showingCamera = true }) {
                    Label("Scan", systemImage: "camera.fill")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding(.top, 10)
        }
        .padding()
    }
    
    private var documentsListView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 16) {
                ForEach(Array(dataManager.documents.enumerated()), id: \.element.id) { index, document in
                    NavigationLink(destination: EnhancedDocumentDetailView(
                        document: binding(for: document)
                    )) {
                        EnhancedDocumentCard(document: document)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
    
    private func binding(for document: Document) -> Binding<Document> {
        guard let index = dataManager.documents.firstIndex(where: { $0.id == document.id }) else {
            fatalError("Document not found")
        }
        return $dataManager.documents[index]
    }
}

struct EnhancedDocumentCard: View {
    let document: Document
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Source icon
                Image(systemName: sourceIcon)
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text(document.title)
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                // Favorite star
                if document.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
                
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            
            Text(document.body)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Stats
            HStack(spacing: 16) {
                Label("\(document.questionCount)", systemImage: "questionmark.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label("\(document.flashcardCount)", systemImage: "rectangle.portrait.on.rectangle.portrait")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(document.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    document.isFavorite ? Color.yellow.opacity(0.3) : Color.blue.opacity(0.1),
                    lineWidth: 1
                )
        )
    }
    
    private var sourceIcon: String {
        switch document.source {
        case .manual: return "doc.text.fill"
        case .camera, .ocr: return "camera.fill"
        case .gallery: return "photo.fill"
        }
    }
}

// Enhanced Detail View with flashcard integration
struct EnhancedDocumentDetailView: View {
    @Binding var document: Document
    @EnvironmentObject var dataManager: DataManager
    @State private var question: String = ""
    @State private var isSearching: Bool = false
    @State private var highlightedRange: Range<String.Index>?
    @State private var answerText: String = ""
    @State private var isEditingDocument: Bool = false
    @State private var editedDocumentText: String = ""
    @FocusState private var isQuestionFieldFocused: Bool
    @FocusState private var isDocumentFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    private let bert = BERT()
    
    var body: some View {
        DocumentDetailView(
            document: $document,
            onDelete: {
                dataManager.deleteDocument(document)
                dismiss()
            }
        )
    }
}

// Flashcards Tab Placeholder
struct FlashcardsTabView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedSet: FlashcardSet?
    @State private var showingReview = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if dataManager.flashcards.isEmpty {
                        emptyFlashcardsView
                    } else {
                        flashcardsListView
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(UIColor.systemBackground),
                        Color(UIColor.secondarySystemBackground)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Flashcards")
            .sheet(isPresented: $showingReview) {
                if let set = selectedSet {
                    FlashcardReviewView(flashcards: set.flashcards)
                        .environmentObject(dataManager)
                }
            }
        }
    }
    
    private var emptyFlashcardsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.portrait.on.rectangle.portrait")
                .font(.system(size: 80))
                .foregroundColor(.purple.opacity(0.6))
            
            Text("No Flashcards Yet")
                .font(.title.bold())
                .foregroundColor(.primary)
            
            Text("Ask questions in your documents to automatically generate flashcards")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 100)
    }
    
    private var flashcardsListView: some View {
        LazyVStack(spacing: 16) {
            ForEach(dataManager.getFlashcardSets()) { set in
                NavigationLink(destination: FlashcardDetailView(set: set)) {
                    FlashcardSetCard(set: set)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct FlashcardSetCard: View {
    let set: FlashcardSet
    
    var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "rectangle.portrait.on.rectangle.portrait.fill")
                        .foregroundColor(.purple)
                    
                    Text(set.documentTitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(set.flashcards.count)")
                        .font(.title3.bold())
                        .foregroundColor(.purple)
                }
                
                HStack(spacing: 16) {
                    Label("\(set.masteredCount) mastered", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Label("\(set.needsRevisionCount) to review", systemImage: "arrow.clockwise.circle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                // Review button
                HStack {
                    Spacer()
                    Label("Start Review", systemImage: "play.fill")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.purple)
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
    }
}

// Flashcard Detail View - Shows all questions and answers
struct FlashcardDetailView: View {
    let set: FlashcardSet
    @EnvironmentObject var dataManager: DataManager
    @State private var showingReview = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Stats
                HStack(spacing: 30) {
                    StatBadge(
                        icon: "rectangle.portrait.on.rectangle.portrait.fill",
                        value: "\(set.flashcards.count)",
                        label: "Total",
                        color: .purple
                    )
                    
                    StatBadge(
                        icon: "checkmark.circle.fill",
                        value: "\(set.masteredCount)",
                        label: "Mastered",
                        color: .green
                    )
                    
                    StatBadge(
                        icon: "arrow.clockwise.circle.fill",
                        value: "\(set.needsRevisionCount)",
                        label: "Review",
                        color: .orange
                    )
                }
                .padding()
                
                // Start Review Button
                Button(action: { showingReview = true }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Review Session")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Flashcard List
                VStack(alignment: .leading, spacing: 12) {
                    Text("All Flashcards")
                        .font(.title2.bold())
                        .padding(.horizontal)
                    
                    ForEach(Array(set.flashcards.enumerated()), id: \.element.id) { index, flashcard in
                        FlashcardContentCard(flashcard: flashcard, index: index + 1)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .padding(.vertical)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(UIColor.systemBackground),
                    Color(UIColor.secondarySystemBackground)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle(set.documentTitle)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingReview) {
            FlashcardReviewView(flashcards: set.flashcards)
                .environmentObject(dataManager)
        }
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title.bold())
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

struct FlashcardContentCard: View {
    let flashcard: Flashcard
    let index: Int
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("#\(index)")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple)
                    .cornerRadius(6)
                
                if flashcard.isKnown {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .foregroundColor(.purple)
                        .font(.title3)
                }
            }
            
            // Question
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(.purple)
                    Text("Question")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
                
                Text(flashcard.question)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Answer (expandable)
            if isExpanded {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.green)
                        Text("Answer")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                    }
                    
                    Text(flashcard.answer)
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                
                // Stats
                if flashcard.reviewCount > 0 {
                    Divider()
                    
                    HStack(spacing: 16) {
                        Label("\(flashcard.reviewCount) reviews", systemImage: "arrow.clockwise")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let lastReview = flashcard.lastReviewed {
                            Text("Last: \(lastReview, style: .relative)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// Camera Placeholder
struct CameraPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Camera Feature")
                    .font(.title.bold())
                
                Text("OCR camera scanning will be implemented here using Vision framework")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("Scan Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
