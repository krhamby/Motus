//
//  MaintenanceListView.swift
//  Motus
//
//  Complete maintenance history
//

import SwiftUI
import SwiftData

struct MaintenanceListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MaintenanceRecord.date, order: .reverse) private var maintenanceRecords: [MaintenanceRecord]
    @Query private var vehicles: [Vehicle]

    @State private var showingAddRecord = false
    @State private var selectedVehicle: Vehicle?
    @State private var selectedType: MaintenanceType?
    @State private var searchText = ""

    var filteredRecords: [MaintenanceRecord] {
        var records = maintenanceRecords

        if let vehicle = selectedVehicle {
            records = records.filter { $0.vehicle == vehicle }
        }

        if let type = selectedType {
            records = records.filter { $0.maintenanceType == type }
        }

        if !searchText.isEmpty {
            records = records.filter {
                $0.maintenanceType.rawValue.localizedCaseInsensitiveContains(searchText) ||
                $0.serviceProvider.localizedCaseInsensitiveContains(searchText) ||
                $0.notes.localizedCaseInsensitiveContains(searchText)
            }
        }

        return records
    }

    var totalCost: Double {
        filteredRecords.reduce(0) { $0 + $1.cost }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Summary Card
                if !filteredRecords.isEmpty {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Total Maintenance Cost")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(String(format: "$%.2f", totalCost))
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Records")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("\(filteredRecords.count)")
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding()
                }

                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Menu {
                            Button("All Vehicles") {
                                selectedVehicle = nil
                            }
                            ForEach(vehicles) { vehicle in
                                Button(vehicle.displayName) {
                                    selectedVehicle = vehicle
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "car.fill")
                                Text(selectedVehicle?.displayName ?? "All Vehicles")
                                Image(systemName: "chevron.down")
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedVehicle != nil ? Color.accentColor : Color(.systemGray5))
                            .foregroundStyle(selectedVehicle != nil ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        Menu {
                            Button("All Types") {
                                selectedType = nil
                            }
                            ForEach(MaintenanceType.allCases, id: \.self) { type in
                                Button(type.rawValue) {
                                    selectedType = type
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "wrench.fill")
                                Text(selectedType?.rawValue ?? "All Types")
                                Image(systemName: "chevron.down")
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedType != nil ? Color.accentColor : Color(.systemGray5))
                            .foregroundStyle(selectedType != nil ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)

                // Records List
                if filteredRecords.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("No Maintenance Records")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Add maintenance records to track your vehicle's service history")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredRecords) { record in
                            NavigationLink(destination: MaintenanceDetailView(record: record)) {
                                MaintenanceRecordCell(record: record)
                            }
                        }
                        .onDelete(perform: deleteRecords)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Maintenance")
            .searchable(text: $searchText, prompt: "Search records")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddRecord = true
                    } label: {
                        Label("Add Record", systemImage: "plus")
                    }
                    .disabled(vehicles.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddRecord) {
                AddEditMaintenanceView()
            }
        }
    }

    private func deleteRecords(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredRecords[index])
            }
        }
    }
}

struct MaintenanceRecordCell: View {
    let record: MaintenanceRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(record.maintenanceType.rawValue)
                    .font(.headline)
                Spacer()
                Text(String(format: "$%.2f", record.cost))
                    .font(.headline)
                    .foregroundStyle(.accent)
            }

            HStack {
                if let vehicle = record.vehicle {
                    Label(vehicle.displayName, systemImage: "car.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Label("\(record.mileage) mi", systemImage: "gauge")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                if !record.serviceProvider.isEmpty {
                    Text(record.serviceProvider)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(record.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if record.partsUsed.count > 0 {
                HStack {
                    Image(systemName: "gearshape.2.fill")
                        .font(.caption2)
                    Text("\(record.partsUsed.count) parts used")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    MaintenanceListView()
        .modelContainer(for: MaintenanceRecord.self, inMemory: true)
}
