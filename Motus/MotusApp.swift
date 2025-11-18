//
//  MotusApp.swift
//  Motus
//
//  Created by Kevin Hamby on 10/7/25.
//

import SwiftUI
import SwiftData

@main
struct MotusApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Vehicle.self,
            MaintenanceRecord.self,
            FuelLog.self,
            Part.self,
            ServiceReminder.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
