//
//  SemanticSearch.swift
//  Motus
//
//  Semantic search and retrieval system for finding relevant document chunks
//  Uses NaturalLanguage framework for embeddings and similarity scoring
//

import Foundation
import NaturalLanguage

/// Result of a semantic search operation
struct SearchResult {
    let chunk: DocumentChunk
    let relevanceScore: Double
    let matchType: MatchType

    enum MatchType {
        case keyword      // Matched by keywords
        case semantic     // Matched by semantic similarity
        case hybrid       // Both keyword and semantic match
    }
}

/// Semantic search engine for finding relevant document chunks
class SemanticSearch {

    private let embeddingModel: NLEmbedding?

    init() {
        // Load the word embedding model for semantic similarity
        // Using the default English word embedding
        self.embeddingModel = NLEmbedding.wordEmbedding(for: .english)
    }

    /// Searches for relevant chunks based on a user query
    /// - Parameters:
    ///   - query: User's search query
    ///   - chunks: All available document chunks
    ///   - topK: Number of top results to return
    /// - Returns: Sorted array of search results by relevance
    func search(query: String, in chunks: [DocumentChunk], topK: Int = 5) -> [SearchResult] {
        var results: [SearchResult] = []

        for chunk in chunks {
            // Calculate both keyword and semantic similarity
            let keywordScore = calculateKeywordSimilarity(query: query, chunk: chunk)
            let semanticScore = calculateSemanticSimilarity(query: query, chunkText: chunk.content)

            // Hybrid scoring: weighted combination
            let hybridScore = (keywordScore * 0.4) + (semanticScore * 0.6)

            // Determine match type
            let matchType: SearchResult.MatchType
            if keywordScore > 0.3 && semanticScore > 0.3 {
                matchType = .hybrid
            } else if keywordScore > semanticScore {
                matchType = .keyword
            } else {
                matchType = .semantic
            }

            results.append(SearchResult(
                chunk: chunk,
                relevanceScore: hybridScore,
                matchType: matchType
            ))
        }

        // Sort by relevance score and return top K
        return results
            .sorted { $0.relevanceScore > $1.relevanceScore }
            .prefix(topK)
            .map { $0 }
    }

    /// Calculates keyword-based similarity using TF-IDF-like scoring
    private func calculateKeywordSimilarity(query: String, chunk: DocumentChunk) -> Double {
        let queryWords = extractWords(from: query)
        let chunkKeywords = Set(chunk.keywords)
        let chunkWords = extractWords(from: chunk.content)

        var matchCount = 0
        var totalWeight = 0.0

        for word in queryWords {
            // Direct keyword match (higher weight)
            if chunkKeywords.contains(word) {
                matchCount += 1
                totalWeight += 2.0
            }
            // Content match (lower weight)
            else if chunkWords.contains(word) {
                matchCount += 1
                totalWeight += 1.0
            }
        }

        // Normalize by query length
        guard !queryWords.isEmpty else { return 0.0 }
        return min(totalWeight / Double(queryWords.count), 1.0)
    }

    /// Calculates semantic similarity using word embeddings
    private func calculateSemanticSimilarity(query: String, chunkText: String) -> Double {
        guard let embedding = embeddingModel else {
            // Fallback to simple word overlap if embeddings unavailable
            return calculateWordOverlap(query: query, text: chunkText)
        }

        // Get embeddings for query and chunk
        let queryWords = extractWords(from: query)
        let chunkWords = extractWords(from: chunkText)

        // Calculate average embedding for query
        var queryVectors: [[Double]] = []
        for word in queryWords {
            if let vector = embedding.vector(for: word) {
                queryVectors.append(vector)
            }
        }

        // Calculate average embedding for chunk (sample first 100 words for performance)
        var chunkVectors: [[Double]] = []
        for word in chunkWords.prefix(100) {
            if let vector = embedding.vector(for: word) {
                chunkVectors.append(vector)
            }
        }

        guard !queryVectors.isEmpty && !chunkVectors.isEmpty else {
            return calculateWordOverlap(query: query, text: chunkText)
        }

        // Calculate average vectors
        let queryAvg = averageVector(queryVectors)
        let chunkAvg = averageVector(chunkVectors)

        // Calculate cosine similarity
        return cosineSimilarity(queryAvg, chunkAvg)
    }

    /// Simple word overlap calculation as fallback
    private func calculateWordOverlap(query: String, text: String) -> Double {
        let queryWords = Set(extractWords(from: query))
        let textWords = Set(extractWords(from: text))

        let intersection = queryWords.intersection(textWords)
        guard !queryWords.isEmpty else { return 0.0 }

        return Double(intersection.count) / Double(queryWords.count)
    }

    /// Extracts meaningful words from text
    private func extractWords(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text

        var words: [String] = []

        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .lexicalClass,
            options: [.omitWhitespace, .omitPunctuation]
        ) { tag, range in
            let word = String(text[range]).lowercased()

            // Include nouns, verbs, and adjectives
            if (tag == .noun || tag == .verb || tag == .adjective) && word.count > 2 {
                words.append(word)
            }
            return true
        }

        return words
    }

    /// Calculates average of multiple vectors
    private func averageVector(_ vectors: [[Double]]) -> [Double] {
        guard !vectors.isEmpty else { return [] }

        let dimension = vectors[0].count
        var avgVector = [Double](repeating: 0.0, count: dimension)

        for vector in vectors {
            for (i, value) in vector.enumerated() {
                avgVector[i] += value
            }
        }

        return avgVector.map { $0 / Double(vectors.count) }
    }

    /// Calculates cosine similarity between two vectors
    private func cosineSimilarity(_ v1: [Double], _ v2: [Double]) -> Double {
        guard v1.count == v2.count, !v1.isEmpty else { return 0.0 }

        var dotProduct = 0.0
        var magnitude1 = 0.0
        var magnitude2 = 0.0

        for i in 0..<v1.count {
            dotProduct += v1[i] * v2[i]
            magnitude1 += v1[i] * v1[i]
            magnitude2 += v2[i] * v2[i]
        }

        let denominator = sqrt(magnitude1) * sqrt(magnitude2)
        guard denominator > 0 else { return 0.0 }

        return dotProduct / denominator
    }

    /// Finds chunks by page number
    /// - Parameters:
    ///   - pageNumber: Page number to search
    ///   - chunks: All available chunks
    /// - Returns: Chunks that appear on the specified page
    func findChunks(onPage pageNumber: Int, in chunks: [DocumentChunk]) -> [DocumentChunk] {
        return chunks.filter { $0.pageNumbers.contains(pageNumber) }
    }

    /// Finds chunks by section heading
    /// - Parameters:
    ///   - heading: Section heading to search for
    ///   - chunks: All available chunks
    /// - Returns: Chunks with matching section heading
    func findChunks(withHeading heading: String, in chunks: [DocumentChunk]) -> [DocumentChunk] {
        return chunks.filter {
            $0.sectionHeading?.localizedCaseInsensitiveContains(heading) == true
        }
    }
}
