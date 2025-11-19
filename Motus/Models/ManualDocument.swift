//
//  ManualDocument.swift
//  Motus
//
//  AI-powered car manual document storage model
//

import Foundation
import SwiftData

/// Represents a car manual PDF document with associated metadata
@Model
final class ManualDocument {
    /// Unique identifier
    var id: UUID

    /// Display name of the manual (e.g., "2024 Tesla Model 3 Owner's Manual")
    var name: String

    /// Car make (e.g., "Tesla")
    var carMake: String?

    /// Car model (e.g., "Model 3")
    var carModel: String?

    /// Car year
    var year: Int?

    /// Date the document was uploaded
    var uploadedDate: Date

    /// File size in bytes
    var fileSize: Int64

    /// Total number of pages in the PDF
    var pageCount: Int

    /// PDF data stored as binary
    @Attribute(.externalStorage)
    var pdfData: Data

    /// Full extracted text from the PDF
    @Attribute(.externalStorage)
    var fullText: String

    /// Text chunks for RAG retrieval
    @Relationship(deleteRule: .cascade)
    var chunks: [DocumentChunk]

    /// Whether the document has been processed and chunked
    var isProcessed: Bool

    /// Processing error message if any
    var processingError: String?

    init(
        id: UUID = UUID(),
        name: String,
        carMake: String? = nil,
        carModel: String? = nil,
        year: Int? = nil,
        uploadedDate: Date = Date(),
        fileSize: Int64 = 0,
        pageCount: Int = 0,
        pdfData: Data,
        fullText: String = "",
        isProcessed: Bool = false,
        processingError: String? = nil
    ) {
        self.id = id
        self.name = name
        self.carMake = carMake
        self.carModel = carModel
        self.year = year
        self.uploadedDate = uploadedDate
        self.fileSize = fileSize
        self.pageCount = pageCount
        self.pdfData = pdfData
        self.fullText = fullText
        self.chunks = []
        self.isProcessed = isProcessed
        self.processingError = processingError
    }
}
