//
//  ServiceReminder.swift
//  Motus
//
//  Service reminders based on time and mileage
//

import Foundation
import SwiftData

enum ReminderType: String, Codable, CaseIterable {
    case mileageBased = "Mileage-Based"
    case timeBased = "Time-Based"
    case both = "Both Time and Mileage"
}

@Model
final class ServiceReminder {
    var title: String
    var serviceType: String // MaintenanceType
    var reminderType: String // ReminderType
    var targetMileage: Int?
    var targetDate: Date?
    var mileageInterval: Int?
    var timeInterval: Int? // months
    var isCompleted: Bool
    var completedDate: Date?
    var notes: String
    var notifyInAdvance: Bool
    var advanceMileage: Int?
    var advanceDays: Int?

    // Relationships
    var vehicle: Vehicle?

    init(
        title: String,
        serviceType: MaintenanceType = .other,
        reminderType: ReminderType = .both,
        targetMileage: Int? = nil,
        targetDate: Date? = nil,
        mileageInterval: Int? = nil,
        timeInterval: Int? = nil,
        notifyInAdvance: Bool = true,
        advanceMileage: Int? = 500,
        advanceDays: Int? = 7,
        notes: String = ""
    ) {
        self.title = title
        self.serviceType = serviceType.rawValue
        self.reminderType = reminderType.rawValue
        self.targetMileage = targetMileage
        self.targetDate = targetDate
        self.mileageInterval = mileageInterval
        self.timeInterval = timeInterval
        self.isCompleted = false
        self.notifyInAdvance = notifyInAdvance
        self.advanceMileage = advanceMileage
        self.advanceDays = advanceDays
        self.notes = notes
    }

    var type: ReminderType {
        ReminderType(rawValue: reminderType) ?? .both
    }

    var maintenanceType: MaintenanceType {
        MaintenanceType(rawValue: serviceType) ?? .other
    }

    func isDue(currentMileage: Int) -> Bool {
        guard !isCompleted else { return false }

        switch type {
        case .mileageBased:
            if let target = targetMileage {
                return currentMileage >= target
            }
        case .timeBased:
            if let target = targetDate {
                return Date() >= target
            }
        case .both:
            if let mileageTarget = targetMileage, currentMileage >= mileageTarget {
                return true
            }
            if let dateTarget = targetDate, Date() >= dateTarget {
                return true
            }
        }

        return false
    }

    func isApproaching(currentMileage: Int) -> Bool {
        guard !isCompleted, notifyInAdvance else { return false }

        switch type {
        case .mileageBased:
            if let target = targetMileage, let advance = advanceMileage {
                return currentMileage >= (target - advance) && currentMileage < target
            }
        case .timeBased:
            if let target = targetDate, let advance = advanceDays {
                let advanceDate = Calendar.current.date(byAdding: .day, value: -advance, to: target)!
                return Date() >= advanceDate && Date() < target
            }
        case .both:
            if let mileageTarget = targetMileage, let mileageAdvance = advanceMileage {
                if currentMileage >= (mileageTarget - mileageAdvance) && currentMileage < mileageTarget {
                    return true
                }
            }
            if let dateTarget = targetDate, let daysAdvance = advanceDays {
                let advanceDate = Calendar.current.date(byAdding: .day, value: -daysAdvance, to: dateTarget)!
                if Date() >= advanceDate && Date() < dateTarget {
                    return true
                }
            }
        }

        return false
    }
}
