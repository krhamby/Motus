//
//  PDFParser.swift
//  Motus
//
//  Service for extracting text and metadata from PDF documents using PDFKit
//

import Foundation
import PDFKit
import SwiftUI

/// Result of PDF parsing operation
struct PDFParseResult {
    let fullText: String
    let pageCount: Int
    let metadata: PDFMetadata
    let pageTexts: [Int: String] // Page number to text mapping
}

/// Metadata extracted from PDF
struct PDFMetadata {
    let title: String?
    let author: String?
    let subject: String?
    let creator: String?
    let producer: String?
    let creationDate: Date?
    let modificationDate: Date?
}

/// Service for parsing PDF documents and extracting text content
class PDFParser {

    /// Parses a PDF document and extracts all text content
    /// - Parameter data: Raw PDF data
    /// - Returns: Parsed result with text, metadata, and page information
    /// - Throws: Error if PDF cannot be parsed
    func parse(data: Data) throws -> PDFParseResult {
        guard let pdfDocument = PDFDocument(data: data) else {
            throw PDFParseError.invalidPDF
        }

        let pageCount = pdfDocument.pageCount
        guard pageCount > 0 else {
            throw PDFParseError.emptyDocument
        }

        // Extract text from all pages
        var fullText = ""
        var pageTexts: [Int: String] = [:]

        for pageIndex in 0..<pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }

            if let pageText = page.string {
                let cleanedText = cleanText(pageText)
                fullText += cleanedText + "\n\n"
                pageTexts[pageIndex + 1] = cleanedText // 1-indexed page numbers
            }
        }

        // Extract metadata
        let metadata = extractMetadata(from: pdfDocument)

        return PDFParseResult(
            fullText: fullText.trimmingCharacters(in: .whitespacesAndNewlines),
            pageCount: pageCount,
            metadata: metadata,
            pageTexts: pageTexts
        )
    }

    /// Extracts metadata from PDF document
    private func extractMetadata(from document: PDFDocument) -> PDFMetadata {
        let attributes = document.documentAttributes

        return PDFMetadata(
            title: attributes?[PDFDocumentAttribute.titleAttribute] as? String,
            author: attributes?[PDFDocumentAttribute.authorAttribute] as? String,
            subject: attributes?[PDFDocumentAttribute.subjectAttribute] as? String,
            creator: attributes?[PDFDocumentAttribute.creatorAttribute] as? String,
            producer: attributes?[PDFDocumentAttribute.producerAttribute] as? String,
            creationDate: attributes?[PDFDocumentAttribute.creationDateAttribute] as? Date,
            modificationDate: attributes?[PDFDocumentAttribute.modificationDateAttribute] as? Date
        )
    }

    /// Cleans extracted text by removing excessive whitespace and formatting
    private func cleanText(_ text: String) -> String {
        // Remove excessive whitespace while preserving paragraph structure
        let lines = text.components(separatedBy: .newlines)
        let cleanedLines = lines.map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return cleanedLines.joined(separator: "\n")
    }

    /// Extracts text from a specific page range
    /// - Parameters:
    ///   - data: PDF data
    ///   - range: Page range to extract (1-indexed)
    /// - Returns: Extracted text from the specified pages
    func extractText(from data: Data, pageRange range: ClosedRange<Int>) throws -> String {
        guard let pdfDocument = PDFDocument(data: data) else {
            throw PDFParseError.invalidPDF
        }

        var text = ""

        for pageNumber in range {
            let pageIndex = pageNumber - 1 // Convert to 0-indexed

            guard pageIndex >= 0, pageIndex < pdfDocument.pageCount else {
                continue
            }

            if let page = pdfDocument.page(at: pageIndex),
               let pageText = page.string {
                text += cleanText(pageText) + "\n\n"
            }
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Searches for text within a PDF document
    /// - Parameters:
    ///   - data: PDF data
    ///   - searchText: Text to search for
    /// - Returns: Array of page numbers containing the search text
    func search(in data: Data, for searchText: String) throws -> [Int] {
        guard let pdfDocument = PDFDocument(data: data) else {
            throw PDFParseError.invalidPDF
        }

        var matchingPages: [Int] = []

        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex),
                  let pageText = page.string else { continue }

            if pageText.localizedCaseInsensitiveContains(searchText) {
                matchingPages.append(pageIndex + 1) // 1-indexed
            }
        }

        return matchingPages
    }
}

/// Errors that can occur during PDF parsing
enum PDFParseError: LocalizedError {
    case invalidPDF
    case emptyDocument
    case pageNotFound

    var errorDescription: String? {
        switch self {
        case .invalidPDF:
            return "The file is not a valid PDF document"
        case .emptyDocument:
            return "The PDF document contains no pages"
        case .pageNotFound:
            return "The requested page was not found"
        }
    }
}
