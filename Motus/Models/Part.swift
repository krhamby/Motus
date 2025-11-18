//
//  Part.swift
//  Motus
//
//  Parts inventory and tracking with serial numbers
//

import Foundation
import SwiftData

enum PartCategory: String, Codable, CaseIterable {
    case engine = "Engine"
    case transmission = "Transmission"
    case brakes = "Brakes"
    case suspension = "Suspension"
    case electrical = "Electrical"
    case exhaust = "Exhaust"
    case cooling = "Cooling"
    case fuel = "Fuel System"
    case interior = "Interior"
    case exterior = "Exterior"
    case tires = "Tires & Wheels"
    case fluids = "Fluids"
    case filters = "Filters"
    case other = "Other"
}

enum PartCondition: String, Codable, CaseIterable {
    case new = "New"
    case oem = "OEM"
    case aftermarket = "Aftermarket"
    case rebuilt = "Rebuilt"
    case used = "Used"
}

@Model
final class Part {
    var name: String
    var partNumber: String
    var serialNumber: String
    var brand: String
    var category: String // PartCategory
    var condition: String // PartCondition
    var cost: Double
    var purchaseDate: Date
    var installationDate: Date?
    var installationMileage: Int?
    var supplier: String
    var warrantyMonths: Int?
    var warrantyMiles: Int?
    var warrantyExpiration: Date?
    var notes: String
    var quantity: Int

    // Relationships
    var vehicle: Vehicle?
    var maintenanceRecord: MaintenanceRecord?

    init(
        name: String,
        partNumber: String = "",
        serialNumber: String = "",
        brand: String = "",
        category: PartCategory = .other,
        condition: PartCondition = .new,
        cost: Double = 0,
        purchaseDate: Date = Date(),
        installationDate: Date? = nil,
        installationMileage: Int? = nil,
        supplier: String = "",
        warrantyMonths: Int? = nil,
        warrantyMiles: Int? = nil,
        notes: String = "",
        quantity: Int = 1
    ) {
        self.name = name
        self.partNumber = partNumber
        self.serialNumber = serialNumber
        self.brand = brand
        self.category = category.rawValue
        self.condition = condition.rawValue
        self.cost = cost
        self.purchaseDate = purchaseDate
        self.installationDate = installationDate
        self.installationMileage = installationMileage
        self.supplier = supplier
        self.warrantyMonths = warrantyMonths
        self.warrantyMiles = warrantyMiles
        self.notes = notes
        self.quantity = quantity

        // Calculate warranty expiration
        if let months = warrantyMonths {
            self.warrantyExpiration = Calendar.current.date(byAdding: .month, value: months, to: purchaseDate)
        }
    }

    var partCategory: PartCategory {
        PartCategory(rawValue: category) ?? .other
    }

    var partCondition: PartCondition {
        PartCondition(rawValue: condition) ?? .new
    }

    var isUnderWarranty: Bool {
        guard let expiration = warrantyExpiration else { return false }
        return expiration > Date()
    }

    var totalCost: Double {
        cost * Double(quantity)
    }
}
