//
//  VehiclesListView.swift
//  Motus
//
//  List of all vehicles
//

import SwiftUI
import SwiftData

struct VehiclesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Vehicle.year, order: .reverse) private var vehicles: [Vehicle]
    @State private var showingAddVehicle = false
    @State private var searchText = ""

    var filteredVehicles: [Vehicle] {
        if searchText.isEmpty {
            return vehicles
        }
        return vehicles.filter { vehicle in
            vehicle.make.localizedCaseInsensitiveContains(searchText) ||
            vehicle.model.localizedCaseInsensitiveContains(searchText) ||
            vehicle.licensePlate.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredVehicles.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("No Vehicles")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Add your first vehicle to start tracking maintenance")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button {
                            showingAddVehicle = true
                        } label: {
                            Label("Add Vehicle", systemImage: "plus")
                                .padding()
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding()
                } else {
                    List {
                        ForEach(filteredVehicles) { vehicle in
                            NavigationLink(destination: VehicleDetailView(vehicle: vehicle)) {
                                VehicleRowView(vehicle: vehicle)
                            }
                        }
                        .onDelete(perform: deleteVehicles)
                    }
                    .searchable(text: $searchText, prompt: "Search vehicles")
                }
            }
            .navigationTitle("My Vehicles")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddVehicle = true
                    } label: {
                        Label("Add Vehicle", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddVehicle) {
                AddEditVehicleView()
            }
        }
    }

    private func deleteVehicles(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredVehicles[index])
            }
        }
    }
}

struct VehicleRowView: View {
    let vehicle: Vehicle

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(vehicle.displayName)
                .font(.headline)

            HStack {
                Label("\(vehicle.currentMileage) mi", systemImage: "gauge")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                if !vehicle.licensePlate.isEmpty {
                    Text(vehicle.licensePlate)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            HStack(spacing: 12) {
                if vehicle.averageMPG > 0 {
                    StatChip(icon: "fuelpump.fill", value: String(format: "%.1f MPG", vehicle.averageMPG))
                }
                if vehicle.totalMaintenanceCost > 0 {
                    StatChip(icon: "wrench.fill", value: String(format: "$%.0f", vehicle.totalMaintenanceCost))
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatChip: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(value)
                .font(.caption)
        }
        .foregroundStyle(.secondary)
    }
}

#Preview {
    VehiclesListView()
        .modelContainer(for: Vehicle.self, inMemory: true)
}
