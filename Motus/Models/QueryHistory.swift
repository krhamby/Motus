//
//  QueryHistory.swift
//  Motus
//
//  Stores user queries and AI responses for conversation history
//

import Foundation
import SwiftData

/// Represents a query-response pair in the AI assistant conversation
@Model
final class QueryHistory {
    /// Unique identifier
    var id: UUID

    /// User's question
    var query: String

    /// AI-generated response
    @Attribute(.externalStorage)
    var response: String

    /// Document that was queried (if any)
    var document: ManualDocument?

    /// Chunks that were used to generate the response
    var relevantChunks: [DocumentChunk]

    /// Timestamp of the query
    var timestamp: Date

    /// Relevance score (0-1) if available
    var relevanceScore: Double?

    /// Whether the user found this helpful
    var wasHelpful: Bool?

    init(
        id: UUID = UUID(),
        query: String,
        response: String,
        document: ManualDocument? = nil,
        relevantChunks: [DocumentChunk] = [],
        timestamp: Date = Date(),
        relevanceScore: Double? = nil,
        wasHelpful: Bool? = nil
    ) {
        self.id = id
        self.query = query
        self.response = response
        self.document = document
        self.relevantChunks = relevantChunks
        self.timestamp = timestamp
        self.relevanceScore = relevanceScore
        self.wasHelpful = wasHelpful
    }
}
