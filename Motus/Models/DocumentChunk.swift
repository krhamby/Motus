//
//  DocumentChunk.swift
//  Motus
//
//  Represents a semantic chunk of text from a manual document for RAG retrieval
//

import Foundation
import SwiftData

/// A semantically meaningful chunk of text extracted from a manual document
@Model
final class DocumentChunk {
    /// Unique identifier
    var id: UUID

    /// The text content of this chunk (200-800 tokens)
    @Attribute(.externalStorage)
    var content: String

    /// Page number(s) where this chunk appears
    var pageNumbers: [Int]

    /// Position/index of this chunk in the document
    var chunkIndex: Int

    /// Approximate token count
    var tokenCount: Int

    /// Section heading or context (if available)
    var sectionHeading: String?

    /// Keywords extracted from this chunk for semantic search
    var keywords: [String]

    /// Parent document this chunk belongs to
    var document: ManualDocument?

    /// Timestamp when this chunk was created
    var createdDate: Date

    /// Embedding vector for semantic similarity (stored as array for simplicity)
    /// In production, you might use a vector database like Pinecone or Qdrant
    @Attribute(.externalStorage)
    var embeddingVector: [Double]?

    init(
        id: UUID = UUID(),
        content: String,
        pageNumbers: [Int] = [],
        chunkIndex: Int = 0,
        tokenCount: Int = 0,
        sectionHeading: String? = nil,
        keywords: [String] = [],
        createdDate: Date = Date(),
        embeddingVector: [Double]? = nil
    ) {
        self.id = id
        self.content = content
        self.pageNumbers = pageNumbers
        self.chunkIndex = chunkIndex
        self.tokenCount = tokenCount
        self.sectionHeading = sectionHeading
        self.keywords = keywords
        self.createdDate = createdDate
        self.embeddingVector = embeddingVector
    }
}
