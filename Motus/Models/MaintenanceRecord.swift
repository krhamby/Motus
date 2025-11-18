//
//  MaintenanceRecord.swift
//  Motus
//
//  Detailed maintenance record tracking
//

import Foundation
import SwiftData

enum MaintenanceType: String, Codable, CaseIterable {
    case oilChange = "Oil Change"
    case tireRotation = "Tire Rotation"
    case brakeService = "Brake Service"
    case transmission = "Transmission Service"
    case coolantFlush = "Coolant Flush"
    case airFilter = "Air Filter"
    case sparkPlugs = "Spark Plugs"
    case batteryReplacement = "Battery Replacement"
    case inspection = "Inspection"
    case alignment = "Wheel Alignment"
    case repair = "Repair"
    case other = "Other"
}

@Model
final class MaintenanceRecord {
    var date: Date
    var type: String // MaintenanceType
    var mileage: Int
    var cost: Double
    var serviceProvider: String
    var technicianName: String
    var laborHours: Double
    var notes: String
    var nextServiceMileage: Int?
    var nextServiceDate: Date?
    var warrantyExpiration: Date?

    // Relationships
    var vehicle: Vehicle?
    @Relationship(deleteRule: .cascade) var partsUsed: [Part] = []

    init(
        date: Date = Date(),
        type: MaintenanceType = .other,
        mileage: Int,
        cost: Double = 0,
        serviceProvider: String = "",
        technicianName: String = "",
        laborHours: Double = 0,
        notes: String = "",
        nextServiceMileage: Int? = nil,
        nextServiceDate: Date? = nil,
        warrantyExpiration: Date? = nil
    ) {
        self.date = date
        self.type = type.rawValue
        self.mileage = mileage
        self.cost = cost
        self.serviceProvider = serviceProvider
        self.technicianName = technicianName
        self.laborHours = laborHours
        self.notes = notes
        self.nextServiceMileage = nextServiceMileage
        self.nextServiceDate = nextServiceDate
        self.warrantyExpiration = warrantyExpiration
    }

    var maintenanceType: MaintenanceType {
        MaintenanceType(rawValue: type) ?? .other
    }

    var partsCost: Double {
        partsUsed.reduce(0) { $0 + $1.cost }
    }

    var laborCost: Double {
        cost - partsCost
    }
}
