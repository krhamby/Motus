//
//  ContentView.swift
//  Motus
//
//  Main navigation and tab bar
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

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

            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Vehicle.self, inMemory: true)
}
