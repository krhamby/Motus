//
//  ReportGenerator.swift
//  Motus
//
//  Generate maintenance and cost reports
//

import Foundation
import SwiftData

struct ReportGenerator {
    static func generateMaintenanceReport(for vehicle: Vehicle) -> String {
        var report = """
        VEHICLE MAINTENANCE REPORT
        ========================

        Vehicle: \(vehicle.displayName)
        VIN: \(vehicle.vin)
        License Plate: \(vehicle.licensePlate)
        Current Mileage: \(vehicle.currentMileage) miles
        Report Generated: \(Date().formatted(date: .long, time: .shortened))

        MAINTENANCE SUMMARY
        ===================
        Total Maintenance Records: \(vehicle.maintenanceRecords.count)
        Total Maintenance Cost: $\(String(format: "%.2f", vehicle.totalMaintenanceCost))

        """

        if !vehicle.maintenanceRecords.isEmpty {
            report += "\nMAINTENANCE HISTORY\n"
            report += "===================\n\n"

            for record in vehicle.maintenanceRecords.sorted(by: { $0.date > $1.date }) {
                report += """
                Date: \(record.date.formatted(date: .long, time: .omitted))
                Type: \(record.maintenanceType.rawValue)
                Mileage: \(record.mileage) miles
                Cost: $\(String(format: "%.2f", record.cost))
                Service Provider: \(record.serviceProvider)

                """

                if !record.notes.isEmpty {
                    report += "Notes: \(record.notes)\n"
                }

                if !record.partsUsed.isEmpty {
                    report += "Parts Used:\n"
                    for part in record.partsUsed {
                        report += "  - \(part.name) ($\(String(format: "%.2f", part.cost)))\n"
                    }
                }

                report += "\n---\n\n"
            }
        }

        return report
    }

    static func generateFuelReport(for vehicle: Vehicle) -> String {
        var report = """
        FUEL ECONOMY REPORT
        ===================

        Vehicle: \(vehicle.displayName)
        Current Mileage: \(vehicle.currentMileage) miles
        Report Generated: \(Date().formatted(date: .long, time: .shortened))

        FUEL SUMMARY
        ============
        Total Fuel Purchases: \(vehicle.fuelLogs.count)
        Total Fuel Cost: $\(String(format: "%.2f", vehicle.totalFuelCost))
        Average MPG: \(String(format: "%.1f", vehicle.averageMPG))

        """

        if !vehicle.fuelLogs.isEmpty {
            report += "\nFUEL PURCHASE HISTORY\n"
            report += "=====================\n\n"

            for log in vehicle.fuelLogs.sorted(by: { $0.date > $1.date }) {
                report += """
                Date: \(log.date.formatted(date: .long, time: .omitted))
                Mileage: \(log.mileage) miles
                Gallons: \(String(format: "%.2f", log.gallons))
                Price/Gallon: $\(String(format: "%.2f", log.pricePerGallon))
                Total Cost: $\(String(format: "%.2f", log.totalCost))
                Location: \(log.location)

                """

                if let mpg = log.mpg {
                    report += "MPG: \(String(format: "%.1f", mpg))\n"
                }

                report += "\n---\n\n"
            }
        }

        return report
    }

    static func generateCombinedReport(for vehicle: Vehicle) -> String {
        var report = """
        COMPLETE VEHICLE REPORT
        =======================

        Vehicle Information
        -------------------
        Make: \(vehicle.make)
        Model: \(vehicle.model)
        Year: \(vehicle.year)
        VIN: \(vehicle.vin)
        License Plate: \(vehicle.licensePlate)
        Current Mileage: \(vehicle.currentMileage) miles
        Color: \(vehicle.color)
        Engine: \(vehicle.engineType)
        Transmission: \(vehicle.transmissionType)
        Purchase Date: \(vehicle.purchaseDate.formatted(date: .long, time: .omitted))

        Report Generated: \(Date().formatted(date: .long, time: .shortened))

        COST SUMMARY
        ============
        Total Maintenance Cost: $\(String(format: "%.2f", vehicle.totalMaintenanceCost))
        Total Fuel Cost: $\(String(format: "%.2f", vehicle.totalFuelCost))
        Total Cost: $\(String(format: "%.2f", vehicle.totalMaintenanceCost + vehicle.totalFuelCost))

        STATISTICS
        ==========
        Maintenance Records: \(vehicle.maintenanceRecords.count)
        Fuel Purchases: \(vehicle.fuelLogs.count)
        Parts in Inventory: \(vehicle.parts.count)
        Average MPG: \(String(format: "%.1f", vehicle.averageMPG))

        """

        // Add maintenance section
        if !vehicle.maintenanceRecords.isEmpty {
            report += generateMaintenanceReport(for: vehicle)
        }

        // Add fuel section
        if !vehicle.fuelLogs.isEmpty {
            report += "\n\n"
            report += generateFuelReport(for: vehicle)
        }

        // Add parts inventory
        if !vehicle.parts.isEmpty {
            report += """

            PARTS INVENTORY
            ===============
            Total Parts: \(vehicle.parts.count)
            Total Value: $\(String(format: "%.2f", vehicle.parts.reduce(0) { $0 + $1.totalCost }))

            """

            for part in vehicle.parts.sorted(by: { $0.purchaseDate > $1.purchaseDate }) {
                report += """

                Part: \(part.name)
                Brand: \(part.brand)
                Category: \(part.partCategory.rawValue)
                Part Number: \(part.partNumber)
                Serial Number: \(part.serialNumber)
                Cost: $\(String(format: "%.2f", part.totalCost))
                Purchase Date: \(part.purchaseDate.formatted(date: .long, time: .omitted))

                """

                if part.isUnderWarranty {
                    report += "Status: Under Warranty\n"
                }

                report += "---\n"
            }
        }

        return report
    }
}

// Extension to make reports shareable
extension String {
    func saveAsTextFile(filename: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)

        do {
            try self.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error saving file: \(error)")
            return nil
        }
    }
}
