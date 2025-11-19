//
//  DocumentChunker.swift
//  Motus
//
//  Intelligent semantic document chunking system for RAG
//  Uses sentence-based and semantic chunking with optimal 200-800 token sizes
//

import Foundation
import NaturalLanguage

/// Configuration for document chunking strategy
struct ChunkingConfiguration {
    /// Target chunk size in characters (roughly ~400 tokens = 1600 characters)
    let targetChunkSize: Int

    /// Minimum chunk size in characters
    let minChunkSize: Int

    /// Maximum chunk size in characters
    let maxChunkSize: Int

    /// Overlap between chunks (in characters) for context preservation
    let overlapSize: Int

    static let `default` = ChunkingConfiguration(
        targetChunkSize: 1600,  // ~400 tokens
        minChunkSize: 800,      // ~200 tokens
        maxChunkSize: 3200,     // ~800 tokens
        overlapSize: 200        // ~50 tokens overlap
    )

    static let large = ChunkingConfiguration(
        targetChunkSize: 2400,  // ~600 tokens
        minChunkSize: 1600,     // ~400 tokens
        maxChunkSize: 4000,     // ~1000 tokens
        overlapSize: 400        // ~100 tokens overlap
    )
}

/// Represents a text chunk with metadata
struct TextChunk {
    let content: String
    let startIndex: Int
    let endIndex: Int
    let pageNumbers: [Int]
    let sectionHeading: String?
    let tokenCount: Int
    let keywords: [String]
}

/// Intelligent document chunking service using semantic and sentence-based strategies
class DocumentChunker {

    private let config: ChunkingConfiguration
    private let tokenizer = NLTokenizer(unit: .sentence)

    init(config: ChunkingConfiguration = .default) {
        self.config = config
    }

    /// Chunks a document's text into semantically meaningful segments
    /// - Parameters:
    ///   - text: Full document text
    ///   - pageTexts: Mapping of page numbers to their text content
    /// - Returns: Array of text chunks optimized for RAG retrieval
    func chunk(text: String, pageTexts: [Int: String]) -> [TextChunk] {
        // First, split into sections based on headings
        let sections = extractSections(from: text)

        var chunks: [TextChunk] = []
        var currentPosition = 0

        for section in sections {
            // Chunk each section individually to preserve semantic coherence
            let sectionChunks = chunkSection(
                section.content,
                heading: section.heading,
                startPosition: currentPosition,
                pageTexts: pageTexts
            )

            chunks.append(contentsOf: sectionChunks)
            currentPosition += section.content.count
        }

        return chunks
    }

    /// Extracts sections from text based on headings and structure
    private func extractSections(from text: String) -> [Section] {
        var sections: [Section] = []
        let lines = text.components(separatedBy: .newlines)

        var currentHeading: String?
        var currentContent = ""

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // Detect headings (ALL CAPS, short lines, or common section markers)
            if isLikelyHeading(trimmedLine) {
                // Save previous section
                if !currentContent.isEmpty {
                    sections.append(Section(
                        heading: currentHeading,
                        content: currentContent.trimmingCharacters(in: .whitespacesAndNewlines)
                    ))
                }

                // Start new section
                currentHeading = trimmedLine
                currentContent = ""
            } else {
                currentContent += line + "\n"
            }
        }

        // Add final section
        if !currentContent.isEmpty {
            sections.append(Section(
                heading: currentHeading,
                content: currentContent.trimmingCharacters(in: .whitespacesAndNewlines)
            ))
        }

        return sections.isEmpty ? [Section(heading: nil, content: text)] : sections
    }

    /// Determines if a line is likely a heading
    private func isLikelyHeading(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // Empty lines are not headings
        guard !trimmed.isEmpty else { return false }

        // Check for common heading patterns
        let isAllCaps = trimmed.uppercased() == trimmed && trimmed.count > 3
        let isShort = trimmed.count < 80
        let hasNoEndPunctuation = !trimmed.hasSuffix(".") && !trimmed.hasSuffix(",")
        let startsWithNumber = trimmed.first?.isNumber == true

        // Common car manual section keywords
        let headingKeywords = [
            "CHAPTER", "SECTION", "WARNING", "CAUTION", "NOTE",
            "MAINTENANCE", "SPECIFICATIONS", "SAFETY", "IMPORTANT",
            "INTRODUCTION", "OVERVIEW", "PROCEDURE", "OPERATION"
        ]

        let hasKeyword = headingKeywords.contains { trimmed.uppercased().contains($0) }

        return (isAllCaps && isShort && hasNoEndPunctuation) ||
               (isShort && startsWithNumber && hasNoEndPunctuation) ||
               hasKeyword
    }

    /// Chunks a section into optimal-sized pieces using sentence boundaries
    private func chunkSection(
        _ text: String,
        heading: String?,
        startPosition: Int,
        pageTexts: [Int: String]
    ) -> [TextChunk] {
        tokenizer.string = text
        var chunks: [TextChunk] = []
        var currentChunk = ""
        var chunkStartIndex = 0

        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = String(text[range])

            // Check if adding this sentence would exceed max chunk size
            if currentChunk.count + sentence.count > config.maxChunkSize && !currentChunk.isEmpty {
                // Create chunk from accumulated sentences
                let chunk = createChunk(
                    from: currentChunk,
                    heading: heading,
                    startIndex: startPosition + chunkStartIndex,
                    endIndex: startPosition + chunkStartIndex + currentChunk.count,
                    pageTexts: pageTexts
                )
                chunks.append(chunk)

                // Start new chunk with overlap
                let overlapText = getOverlapText(from: currentChunk)
                currentChunk = overlapText + sentence
                chunkStartIndex += currentChunk.count - overlapText.count - sentence.count
            } else {
                currentChunk += sentence
            }

            return true
        }

        // Add final chunk if it has content
        if !currentChunk.isEmpty {
            let chunk = createChunk(
                from: currentChunk,
                heading: heading,
                startIndex: startPosition + chunkStartIndex,
                endIndex: startPosition + chunkStartIndex + currentChunk.count,
                pageTexts: pageTexts
            )
            chunks.append(chunk)
        }

        return chunks
    }

    /// Gets overlap text from the end of a chunk for context preservation
    private func getOverlapText(from text: String) -> String {
        guard text.count > config.overlapSize else { return text }

        let startIndex = text.index(text.endIndex, offsetBy: -config.overlapSize)
        return String(text[startIndex...])
    }

    /// Creates a text chunk with metadata
    private func createChunk(
        from content: String,
        heading: String?,
        startIndex: Int,
        endIndex: Int,
        pageTexts: [Int: String]
    ) -> TextChunk {
        // Find which pages this chunk appears on
        let pageNumbers = findPageNumbers(for: content, in: pageTexts)

        // Extract keywords using NaturalLanguage framework
        let keywords = extractKeywords(from: content)

        // Estimate token count (rough: 1 token ≈ 4 characters)
        let tokenCount = content.count / 4

        return TextChunk(
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            startIndex: startIndex,
            endIndex: endIndex,
            pageNumbers: pageNumbers,
            sectionHeading: heading,
            tokenCount: tokenCount,
            keywords: keywords
        )
    }

    /// Finds page numbers where content appears
    private func findPageNumbers(for content: String, in pageTexts: [Int: String]) -> [Int] {
        var pageNumbers: [Int] = []
        let sampleText = String(content.prefix(100)) // Use first 100 chars as sample

        for (pageNum, pageText) in pageTexts {
            if pageText.contains(sampleText) {
                pageNumbers.append(pageNum)
            }
        }

        return pageNumbers.sorted()
    }

    /// Extracts important keywords from text using NaturalLanguage framework
    private func extractKeywords(from text: String, maxKeywords: Int = 10) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lemma, .lexicalClass])
        tagger.string = text

        var keywords: [String: Int] = [:] // Word frequency map

        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .lexicalClass,
            options: [.omitWhitespace, .omitPunctuation]
        ) { tag, range in
            // Extract nouns and verbs as keywords
            if tag == .noun || tag == .verb {
                let word = String(text[range]).lowercased()

                // Filter out very short or common words
                if word.count > 3 && !commonWords.contains(word) {
                    keywords[word, default: 0] += 1
                }
            }
            return true
        }

        // Sort by frequency and return top keywords
        return keywords.sorted { $0.value > $1.value }
            .prefix(maxKeywords)
            .map { $0.key }
    }

    // Common words to exclude from keywords
    private let commonWords: Set<String> = [
        "this", "that", "with", "from", "have", "will", "your", "more",
        "about", "should", "could", "would", "their", "there", "these",
        "those", "when", "where", "which", "while", "being", "been"
    ]
}

/// Represents a document section
private struct Section {
    let heading: String?
    let content: String
}
