//
//  FuelLog.swift
//  Motus
//
//  Fuel purchase and efficiency tracking
//

import Foundation
import SwiftData

enum FuelGrade: String, Codable, CaseIterable {
    case regular = "Regular (87)"
    case midGrade = "Mid-Grade (89)"
    case premium = "Premium (91+)"
    case diesel = "Diesel"
    case electric = "Electric"
}

@Model
final class FuelLog {
    var date: Date
    var mileage: Int
    var gallons: Double
    var pricePerGallon: Double
    var totalCost: Double
    var location: String
    var fuelGrade: String // FuelGrade
    var fullTank: Bool
    var notes: String
    var octaneRating: Int?

    // Calculated fields
    var tripMiles: Int?
    var mpg: Double?

    // Relationships
    var vehicle: Vehicle?

    init(
        date: Date = Date(),
        mileage: Int,
        gallons: Double,
        pricePerGallon: Double,
        location: String = "",
        fuelGrade: FuelGrade = .regular,
        fullTank: Bool = true,
        notes: String = "",
        octaneRating: Int? = nil
    ) {
        self.date = date
        self.mileage = mileage
        self.gallons = gallons
        self.pricePerGallon = pricePerGallon
        self.totalCost = gallons * pricePerGallon
        self.location = location
        self.fuelGrade = fuelGrade.rawValue
        self.fullTank = fullTank
        self.notes = notes
        self.octaneRating = octaneRating
    }

    var grade: FuelGrade {
        FuelGrade(rawValue: fuelGrade) ?? .regular
    }

    func calculateMPG(previousMileage: Int) -> Double? {
        guard fullTank, gallons > 0 else { return nil }
        let miles = mileage - previousMileage
        guard miles > 0 else { return nil }
        return Double(miles) / gallons
    }
}
