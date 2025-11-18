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

            PartsListView()
                .tabItem {
                    Label("Parts", systemImage: "gearshape.2.fill")
                }

            // AI Manual Assistant - uses the new RAG-powered implementation
            ManualLibraryView(modelContext: modelContext)
                .tabItem {
                    Label("AI Manual", systemImage: "brain")
                }
        }
    }
}

// DashboardView is now in a separate file or defined elsewhere
// Keeping stub for compatibility
struct DashboardView: View {
    var body: some View {
        Text("Dashboard")
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Vehicle.self, inMemory: true)
}
