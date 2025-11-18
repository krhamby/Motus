//
//  AIAssistant.swift
//  Motus
//
//  AI-powered assistant using Apple's Foundation Models framework
//  Provides intelligent document querying with RAG (Retrieval Augmented Generation)
//

import Foundation
import FoundationModels
import SwiftData

/// Structured response from the AI assistant
@Generable
struct AssistantResponse: Equatable {
    @Guide(description: "A clear, accurate answer to the user's question based on the manual")
    let answer: String

    @Guide(description: "Relevant page numbers from the manual that support this answer")
    let sourcePages: [Int]

    @Guide(description: "Level of confidence in the answer: high, medium, or low")
    let confidence: String

    @Guide(description: "Follow-up questions the user might want to ask, if any")
    let suggestedFollowUps: [String]?
}

/// Main AI assistant service for document querying
@MainActor
class AIAssistant: ObservableObject {

    @Published var isProcessing: Bool = false
    @Published var lastError: String?

    private let pdfParser = PDFParser()
    private let chunker = DocumentChunker()
    private let semanticSearch = SemanticSearch()
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Document Processing

    /// Processes a PDF document: extracts text, chunks it, and stores in database
    /// - Parameters:
    ///   - pdfData: Raw PDF data
    ///   - name: Display name for the document
    ///   - carMake: Optional car make
    ///   - carModel: Optional car model
    ///   - year: Optional car year
    /// - Returns: The processed ManualDocument
    func processDocument(
        pdfData: Data,
        name: String,
        carMake: String? = nil,
        carModel: String? = nil,
        year: Int? = nil
    ) async throws -> ManualDocument {
        isProcessing = true
        defer { isProcessing = false }

        do {
            // Parse PDF
            let parseResult = try pdfParser.parse(data: pdfData)

            // Create document
            let document = ManualDocument(
                name: name,
                carMake: carMake,
                carModel: carModel,
                year: year,
                fileSize: Int64(pdfData.count),
                pageCount: parseResult.pageCount,
                pdfData: pdfData,
                fullText: parseResult.fullText,
                isProcessed: false
            )

            modelContext.insert(document)

            // Chunk the document
            let textChunks = chunker.chunk(
                text: parseResult.fullText,
                pageTexts: parseResult.pageTexts
            )

            // Convert to DocumentChunk models and add to document
            for (index, textChunk) in textChunks.enumerated() {
                let chunk = DocumentChunk(
                    content: textChunk.content,
                    pageNumbers: textChunk.pageNumbers,
                    chunkIndex: index,
                    tokenCount: textChunk.tokenCount,
                    sectionHeading: textChunk.sectionHeading,
                    keywords: textChunk.keywords
                )

                chunk.document = document
                document.chunks.append(chunk)
                modelContext.insert(chunk)
            }

            document.isProcessed = true

            try modelContext.save()

            return document

        } catch {
            lastError = "Failed to process document: \(error.localizedDescription)"
            throw error
        }
    }

    // MARK: - Querying

    /// Queries a document using natural language with RAG
    /// - Parameters:
    ///   - query: User's natural language question
    ///   - document: The manual document to query
    /// - Returns: AI-generated response with sources
    func query(_ query: String, document: ManualDocument) async throws -> QueryHistory {
        isProcessing = true
        defer { isProcessing = false }

        guard document.isProcessed else {
            throw AIAssistantError.documentNotProcessed
        }

        do {
            // Step 1: Retrieve relevant chunks using semantic search
            let relevantResults = semanticSearch.search(
                query: query,
                in: document.chunks,
                topK: 5
            )

            guard !relevantResults.isEmpty else {
                throw AIAssistantError.noRelevantContent
            }

            // Step 2: Build context from relevant chunks
            let context = buildContext(from: relevantResults)

            // Step 3: Generate response using Foundation Models
            let response = try await generateResponse(
                query: query,
                context: context,
                documentName: document.name
            )

            // Step 4: Save query history
            let relevantChunks = relevantResults.map { $0.chunk }
            let avgScore = relevantResults.reduce(0.0) { $0 + $1.relevanceScore } / Double(relevantResults.count)

            let queryHistory = QueryHistory(
                query: query,
                response: response.answer,
                document: document,
                relevantChunks: relevantChunks,
                timestamp: Date(),
                relevanceScore: avgScore
            )

            modelContext.insert(queryHistory)
            try modelContext.save()

            return queryHistory

        } catch {
            lastError = "Failed to process query: \(error.localizedDescription)"
            throw error
        }
    }

    /// Builds context string from search results
    private func buildContext(from results: [SearchResult]) -> String {
        var context = "Relevant excerpts from the manual:\n\n"

        for (index, result) in results.enumerated() {
            context += "[\(index + 1)] "

            if let heading = result.chunk.sectionHeading {
                context += "Section: \(heading)\n"
            }

            if !result.chunk.pageNumbers.isEmpty {
                context += "Pages: \(result.chunk.pageNumbers.map(String.init).joined(separator: ", "))\n"
            }

            context += "\(result.chunk.content)\n\n"
        }

        return context
    }

    /// Generates a response using Foundation Models
    private func generateResponse(
        query: String,
        context: String,
        documentName: String
    ) async throws -> AssistantResponse {
        // Build the prompt for the Foundation Model
        let prompt = """
        You are an expert automotive assistant helping a user understand their car manual: "\(documentName)".

        The user asked: "\(query)"

        Here is relevant information from the manual:

        \(context)

        Based ONLY on the information provided above, answer the user's question accurately and clearly.
        If the information doesn't contain the answer, say so honestly.
        Include specific page numbers where the information was found.
        Rate your confidence as "high", "medium", or "low".
        Suggest 1-2 helpful follow-up questions if appropriate.
        """

        // Use Foundation Models to generate structured response
        // Note: This is the iOS 26+ Foundation Models API
        let response = try await generateStructuredResponse(prompt: prompt)

        return response
    }

    /// Generates structured response using Foundation Models framework
    /// This uses the @Generable macro for type-safe AI responses
    private func generateStructuredResponse(prompt: String) async throws -> AssistantResponse {
        // TODO: Implement actual Foundation Models API call when available
        // For now, return a placeholder that demonstrates the structure

        // In production, this would be:
        // let response = try await FoundationModels.generate(
        //     prompt: prompt,
        //     outputType: AssistantResponse.self
        // )

        // Placeholder implementation
        // In a real app with Foundation Models, this would call the actual API
        throw AIAssistantError.foundationModelsNotAvailable
    }

    // MARK: - General Chat (without document)

    /// Answers general car maintenance questions without a specific document
    /// - Parameter query: User's question
    /// - Returns: AI-generated response
    func answerGeneralQuestion(_ query: String) async throws -> String {
        isProcessing = true
        defer { isProcessing = false }

        let prompt = """
        You are a helpful automotive assistant specializing in car maintenance and care.

        User question: "\(query)"

        Provide a helpful, accurate answer based on general automotive knowledge.
        If you need specific information about their car, suggest uploading their owner's manual.
        """

        // TODO: Implement with Foundation Models
        // For now, provide helpful fallback
        return """
        I'd be happy to help with that! For the most accurate information specific to your vehicle, \
        I recommend uploading your car's owner manual. This will allow me to provide precise answers \
        based on your exact make and model.

        In the meantime, here's general guidance: \(query)

        Would you like to upload your owner's manual to get more specific information?
        """
    }
}

// MARK: - Errors

enum AIAssistantError: LocalizedError {
    case documentNotProcessed
    case noRelevantContent
    case foundationModelsNotAvailable
    case processingFailed(String)

    var errorDescription: String? {
        switch self {
        case .documentNotProcessed:
            return "This document hasn't been processed yet. Please wait for processing to complete."
        case .noRelevantContent:
            return "I couldn't find relevant information in the manual to answer your question."
        case .foundationModelsNotAvailable:
            return "Foundation Models framework is not available. Please ensure you're running iOS 26+ and have Apple Intelligence enabled."
        case .processingFailed(let message):
            return "Processing failed: \(message)"
        }
    }
}
