//
//  ManualLibraryView.swift
//  Motus
//
//  View for managing uploaded car manuals
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ManualLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ManualDocument.uploadedDate, order: .reverse) private var documents: [ManualDocument]

    @StateObject private var assistant: AIAssistant

    @State private var showingImporter = false
    @State private var showingAddSheet = false
    @State private var isProcessing = false
    @State private var processingProgress: String = ""

    init(modelContext: ModelContext) {
        _assistant = StateObject(wrappedValue: AIAssistant(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            Group {
                if documents.isEmpty {
                    emptyStateView
                } else {
                    documentListView
                }
            }
            .navigationTitle("My Manuals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingImporter = true
                    } label: {
                        Label("Add Manual", systemImage: "plus")
                    }
                }
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .overlay {
                if isProcessing {
                    processingOverlay
                }
            }
        }
    }

    // MARK: - Views

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Manuals", systemImage: "book.closed")
        } description: {
            Text("Upload your car's owner manual to ask questions and get instant answers")
        } actions: {
            Button("Upload Manual") {
                showingImporter = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var documentListView: some View {
        List {
            ForEach(documents) { document in
                NavigationLink(destination: ManualDetailView(document: document, assistant: assistant)) {
                    ManualRowView(document: document)
                }
            }
            .onDelete(perform: deleteDocuments)
        }
    }

    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ProgressView()
                    .controlSize(.large)
                    .scaleEffect(1.5)
                    .tint(.white)

                VStack(spacing: 8) {
                    Text("Processing Manual")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    Text(processingProgress)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(48)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
            )
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        }
    }

    // MARK: - Actions

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            // Read PDF data
            guard let pdfData = try? Data(contentsOf: url) else {
                return
            }

            let fileName = url.deletingPathExtension().lastPathComponent

            Task {
                await processDocument(pdfData: pdfData, name: fileName)
            }

        case .failure(let error):
            print("File import error: \(error)")
        }
    }

    @MainActor
    private func processDocument(pdfData: Data, name: String) async {
        isProcessing = true
        processingProgress = "Analyzing PDF..."

        // Give UI time to show the overlay
        try? await Task.sleep(for: .milliseconds(100))

        do {
            processingProgress = "Extracting text from pages..."
            try? await Task.sleep(for: .milliseconds(100))

            processingProgress = "Creating intelligent chunks..."
            try? await Task.sleep(for: .milliseconds(100))

            let _ = try await assistant.processDocument(
                pdfData: pdfData,
                name: name
            )

            processingProgress = "Done!"
            try? await Task.sleep(for: .milliseconds(500))

        } catch {
            processingProgress = "Error: \(error.localizedDescription)"
            try? await Task.sleep(for: .seconds(2))
        }

        isProcessing = false
    }

    private func deleteDocuments(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(documents[index])
        }
    }
}

// MARK: - Manual Row View

struct ManualRowView: View {
    let document: ManualDocument

    var body: some View {
        HStack(spacing: 16) {
            // Document icon
            Image(systemName: document.isProcessed ? "doc.fill" : "doc.badge.clock")
                .font(.title)
                .foregroundStyle(document.isProcessed ? .blue : .orange)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)

            // Document info
            VStack(alignment: .leading, spacing: 4) {
                Text(document.name)
                    .font(.headline)
                    .lineLimit(2)

                if let make = document.carMake, let model = document.carModel {
                    Text("\(make) \(model)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Label("\(document.pageCount) pages", systemImage: "doc.text")
                    Label("\(document.chunks.count) sections", systemImage: "rectangle.split.3x1")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if !document.isProcessed {
                    Label("Processing...", systemImage: "hourglass")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
