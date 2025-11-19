//
//  Vehicle.swift
//  Motus
//
//  Car maintenance tracking app
//

import Foundation
import SwiftData

@Model
final class Vehicle {
    var make: String
    var model: String
    var year: Int
    var vin: String
    var licensePlate: String
    var purchaseDate: Date
    var currentMileage: Int
    var color: String
    var engineType: String
    var transmissionType: String
    var notes: String

    // Relationships
    @Relationship(deleteRule: .cascade) var maintenanceRecords: [MaintenanceRecord] = []
    @Relationship(deleteRule: .cascade) var fuelLogs: [FuelLog] = []
    @Relationship(deleteRule: .cascade) var parts: [Part] = []
    @Relationship(deleteRule: .cascade) var serviceReminders: [ServiceReminder] = []

    init(
        make: String,
        model: String,
        year: Int,
        vin: String = "",
        licensePlate: String = "",
        purchaseDate: Date = Date(),
        currentMileage: Int = 0,
        color: String = "",
        engineType: String = "",
        transmissionType: String = "",
        notes: String = ""
    ) {
        self.make = make
        self.model = model
        self.year = year
        self.vin = vin
        self.licensePlate = licensePlate
        self.purchaseDate = purchaseDate
        self.currentMileage = currentMileage
        self.color = color
        self.engineType = engineType
        self.transmissionType = transmissionType
        self.notes = notes
    }

    var displayName: String {
        "\(year) \(make) \(model)"
    }

    var totalMaintenanceCost: Double {
        maintenanceRecords.reduce(0) { $0 + $1.cost }
    }

    var totalFuelCost: Double {
        fuelLogs.reduce(0) { $0 + $1.totalCost }
    }

    var averageMPG: Double {
        guard fuelLogs.count > 1 else { return 0 }

        let sortedLogs = fuelLogs.sorted { $0.date < $1.date }
        var totalMPG = 0.0
        var count = 0

        for i in 1..<sortedLogs.count {
            let milesDriven = Double(sortedLogs[i].mileage - sortedLogs[i-1].mileage)
            let gallons = sortedLogs[i].gallons
            if gallons > 0 {
                totalMPG += milesDriven / gallons
                count += 1
            }
        }

        return count > 0 ? totalMPG / Double(count) : 0
    }
}
