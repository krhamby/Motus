//
//  ContentView.swift
//  Motus
//
//  Main navigation and tab bar
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "gauge.high")
                }

            VehiclesListView()
                .tabItem {
                    Label("Vehicles", systemImage: "car.fill")
                }

            MaintenanceListView()
                .tabItem {
                    Label("Maintenance", systemImage: "wrench.fill")
                }

            FuelLogsListView()
                .tabItem {
                    Label("Fuel", systemImage: "fuelpump.fill")
                }

            PartsListView()
                .tabItem {
                    Label("Parts", systemImage: "gearshape.2.fill")
                }

            CarManualAssistantView()
                .tabItem {
                    Label("AI Assistant", systemImage: "sparkles")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Vehicle.self, inMemory: true)
}
