//
//  ManualDetailView.swift
//  Motus
//
//  Detail view for a manual with AI chat interface
//

import SwiftUI
import SwiftData

struct ManualDetailView: View {
    let document: ManualDocument
    @ObservedObject var assistant: AIAssistant

    @Query private var queryHistory: [QueryHistory]
    @State private var currentQuery: String = ""
    @State private var isQuerying = false
    @State private var errorMessage: String?
    @State private var showError = false
    @FocusState private var isTextFieldFocused: Bool

    init(document: ManualDocument, assistant: AIAssistant) {
        self.document = document
        self.assistant = assistant

        // Filter query history for this document
        let documentID = document.id
        _queryHistory = Query(
            filter: #Predicate<QueryHistory> { query in
                query.document?.id == documentID
            },
            sort: \.timestamp,
            order: .forward
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Document header
            documentHeader
                .padding()
                .background(.ultraThinMaterial)

            Divider()

            // Model availability banner
            if !assistant.modelAvailability.isAvailable {
                modelAvailabilityBanner
            }

            // Chat/query area
            if queryHistory.isEmpty {
                emptyQueryView
            } else {
                queryListView
            }

            Divider()

            // Input area
            queryInputView
        }
        .navigationTitle("AI Assistant")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                showError = false
                errorMessage = nil
            }
            if assistant.modelAvailability == .appleIntelligenceDisabled {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Views

    private var documentHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "book.fill")
                .font(.title2)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(document.name)
                    .font(.headline)

                if let make = document.carMake, let model = document.carModel {
                    Text("\(make) \(model)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text("\(document.chunks.count) sections indexed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var modelAvailabilityBanner: some View {
        HStack(spacing: 12) {
            Group {
                switch assistant.modelAvailability {
                case .checking:
                    ProgressView()
                        .controlSize(.small)
                case .downloading:
                    Image(systemName: "arrow.down.circle")
                        .foregroundStyle(.orange)
                case .appleIntelligenceDisabled:
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                case .deviceNotSupported:
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(.red)
                case .unavailable:
                    Image(systemName: "exclamationmark.circle")
                        .foregroundStyle(.orange)
                case .available:
                    EmptyView()
                }
            }
            .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(assistant.modelAvailability.errorMessage)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                if assistant.modelAvailability == .downloading {
                    Text("This may take a few minutes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if assistant.modelAvailability == .appleIntelligenceDisabled {
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else if assistant.modelAvailability == .checking || assistant.modelAvailability == .downloading {
                Button {
                    Task {
                        await assistant.checkModelAvailability()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(bannerColor)
    }

    private var bannerColor: Color {
        switch assistant.modelAvailability {
        case .checking, .downloading:
            return Color.orange.opacity(0.15)
        case .appleIntelligenceDisabled, .unavailable:
            return Color.orange.opacity(0.15)
        case .deviceNotSupported:
            return Color.red.opacity(0.15)
        case .available:
            return Color.clear
        }
    }

    private var emptyQueryView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.text.bubble.right")
                .font(.system(size: 60))
                .foregroundStyle(.blue.opacity(0.6))

            Text("Ask me anything about your manual")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Try questions like:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                SuggestedQuestionButton(
                    question: "How often should I change the oil?",
                    action: { currentQuery = $0 }
                )
                SuggestedQuestionButton(
                    question: "What tire pressure is recommended?",
                    action: { currentQuery = $0 }
                )
                SuggestedQuestionButton(
                    question: "How do I reset the maintenance light?",
                    action: { currentQuery = $0 }
                )
            }
        }
        .frame(maxHeight: .infinity)
        .padding()
    }

    private var queryListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(queryHistory) { query in
                        QueryBubbleView(query: query)
                            .id(query.id)
                    }

                    if isQuerying {
                        HStack {
                            ProgressView()
                            Text("Thinking...")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                }
                .padding()
            }
            .onChange(of: queryHistory.count) { _, _ in
                if let lastQuery = queryHistory.last {
                    withAnimation {
                        proxy.scrollTo(lastQuery.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var queryInputView: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                TextField(inputPlaceholder, text: $currentQuery, axis: .vertical)
                    .lineLimit(1...4)
                    .disabled(isQuerying || !assistant.modelAvailability.isAvailable)
                    .focused($isTextFieldFocused)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(minHeight: 36)
                    .submitLabel(.send)
                    .onSubmit {
                        submitQuery()
                    }
            }
            .background(Color(.systemGray6))
            .cornerRadius(18)
            .opacity(assistant.modelAvailability.isAvailable ? 1.0 : 0.6)

            Button {
                submitQuery()
            } label: {
                Image(systemName: isQuerying ? "hourglass" : "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(canSendMessage ? .blue : .gray)
            }
            .disabled(!canSendMessage)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private var inputPlaceholder: String {
        if !assistant.modelAvailability.isAvailable {
            return "AI model not available..."
        }
        return "Ask about your manual..."
    }

    private var canSendMessage: Bool {
        !currentQuery.isEmpty && !isQuerying && assistant.modelAvailability.isAvailable
    }

    // MARK: - Actions

    private func submitQuery() {
        let query = currentQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        currentQuery = ""
        isTextFieldFocused = false // Dismiss keyboard
        isQuerying = true

        Task {
            do {
                _ = try await assistant.query(query, document: document)
            } catch {
                // Show error to user
                if let aiError = error as? AIAssistantError {
                    errorMessage = aiError.errorDescription
                } else {
                    errorMessage = "Failed to process query: \(error.localizedDescription)"
                }
                showError = true
            }
            isQuerying = false
        }
    }
}

// MARK: - Supporting Views

struct SuggestedQuestionButton: View {
    let question: String
    let action: (String) -> Void

    var body: some View {
        Button {
            action(question)
        } label: {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text(question)
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(12)
            .background(.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct QueryBubbleView: View {
    let query: QueryHistory

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // User question
            HStack {
                Spacer(minLength: 60)
                Text(query.query)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundStyle(.white)
                    .cornerRadius(20)
                    .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
            }

            // AI response
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.caption)
                        .foregroundStyle(.purple)
                    Text("AI Assistant")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 4)

                HStack {
                    Text(query.response)
                        .font(.body)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray5))
                        .foregroundStyle(.primary)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                    Spacer(minLength: 60)
                }

                // Source pages
                if !query.relevantChunks.isEmpty {
                    let allPages = Set(query.relevantChunks.flatMap { $0.pageNumbers })
                    if !allPages.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.text.fill")
                                .font(.caption2)
                            Text("Pages \(allPages.sorted().map(String.init).joined(separator: ", "))")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                        .padding(.top, 2)
                    }
                }

                // Timestamp
                Text(query.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 4)
            }
        }
    }
}
