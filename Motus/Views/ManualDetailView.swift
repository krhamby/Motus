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
            TextField("Ask about your manual...", text: $currentQuery, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
                .disabled(isQuerying)

            Button {
                submitQuery()
            } label: {
                Image(systemName: isQuerying ? "hourglass" : "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(currentQuery.isEmpty ? .gray : .blue)
            }
            .disabled(currentQuery.isEmpty || isQuerying)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    // MARK: - Actions

    private func submitQuery() {
        let query = currentQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        currentQuery = ""
        isQuerying = true

        Task {
            do {
                _ = try await assistant.query(query, document: document)
            } catch {
                print("Query error: \(error)")
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
        VStack(alignment: .leading, spacing: 12) {
            // User question
            HStack {
                Spacer()
                Text(query.query)
                    .padding(12)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(16)
                    .frame(maxWidth: 300, alignment: .trailing)
            }

            // AI response
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "brain")
                        .foregroundStyle(.purple)
                    Text("AI Assistant")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }

                Text(query.response)
                    .padding(12)
                    .background(.gray.opacity(0.1))
                    .cornerRadius(16)

                // Source pages
                if !query.relevantChunks.isEmpty {
                    let allPages = Set(query.relevantChunks.flatMap { $0.pageNumbers })
                    if !allPages.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.text")
                                .font(.caption2)
                            Text("Sources: Pages \(allPages.sorted().map(String.init).joined(separator: ", "))")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                }

                // Timestamp
                Text(query.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
