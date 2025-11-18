//
//  VehicleDetailView.swift
//  Motus
//
//  Detailed view of a specific vehicle
//

import SwiftUI
import SwiftData
import Charts

struct VehicleDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let vehicle: Vehicle
    @State private var showingEditVehicle = false
    @State private var selectedTab = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vehicle.displayName)
                                .font(.title)
                                .fontWeight(.bold)
                            if !vehicle.licensePlate.isEmpty {
                                Text(vehicle.licensePlate)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Button {
                            showingEditVehicle = true
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title)
                                .foregroundStyle(.accent)
                        }
                    }

                    Divider()

                    // Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(title: "Current Mileage", value: "\(vehicle.currentMileage)", icon: "gauge.high", color: .blue)
                        StatCard(title: "Avg MPG", value: String(format: "%.1f", vehicle.averageMPG), icon: "fuelpump.fill", color: .green)
                        StatCard(title: "Maintenance Cost", value: String(format: "$%.0f", vehicle.totalMaintenanceCost), icon: "wrench.fill", color: .orange)
                        StatCard(title: "Fuel Cost", value: String(format: "$%.0f", vehicle.totalFuelCost), icon: "dollarsign.circle.fill", color: .red)
                    }

                    if !vehicle.vin.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("VIN")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(vehicle.vin)
                                .font(.caption)
                                .fontDesign(.monospaced)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Tabbed Content
                Picker("View", selection: $selectedTab) {
                    Text("Maintenance").tag(0)
                    Text("Fuel").tag(1)
                    Text("Parts").tag(2)
                    Text("Reminders").tag(3)
                }
                .pickerStyle(.segmented)

                Group {
                    switch selectedTab {
                    case 0:
                        MaintenanceListSection(records: vehicle.maintenanceRecords.sorted(by: { $0.date > $1.date }))
                    case 1:
                        FuelLogsSection(logs: vehicle.fuelLogs.sorted(by: { $0.date > $1.date }))
                    case 2:
                        PartsListSection(parts: vehicle.parts.sorted(by: { $0.purchaseDate > $1.purchaseDate }))
                    case 3:
                        RemindersSection(reminders: vehicle.serviceReminders, currentMileage: vehicle.currentMileage)
                    default:
                        EmptyView()
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditVehicle) {
            AddEditVehicleView(vehicle: vehicle)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct MaintenanceListSection: View {
    let records: [MaintenanceRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Maintenance")
                .font(.headline)

            if records.isEmpty {
                EmptyStateView(
                    icon: "wrench.and.screwdriver",
                    title: "No Maintenance Records",
                    message: "Maintenance history will appear here"
                )
            } else {
                ForEach(records.prefix(5)) { record in
                    MaintenanceRecordRow(record: record)
                }
            }
        }
    }
}

struct MaintenanceRecordRow: View {
    let record: MaintenanceRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.maintenanceType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(record.mileage) mi")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "$%.2f", record.cost))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(record.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct FuelLogsSection: View {
    let logs: [FuelLog]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Fuel Logs")
                .font(.headline)

            if logs.isEmpty {
                EmptyStateView(
                    icon: "fuelpump.fill",
                    title: "No Fuel Logs",
                    message: "Fuel purchase history will appear here"
                )
            } else {
                ForEach(logs.prefix(5)) { log in
                    FuelLogRow(log: log)
                }
            }
        }
    }
}

struct FuelLogRow: View {
    let log: FuelLog

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(String(format: "%.2f", log.gallons)) gal")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(log.location.isEmpty ? "Unknown location" : log.location)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "$%.2f", log.totalCost))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(log.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct PartsListSection: View {
    let parts: [Part]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Parts Inventory")
                .font(.headline)

            if parts.isEmpty {
                EmptyStateView(
                    icon: "gearshape.2.fill",
                    title: "No Parts",
                    message: "Parts inventory will appear here"
                )
            } else {
                ForEach(parts.prefix(5)) { part in
                    PartRow(part: part)
                }
            }
        }
    }
}

struct PartRow: View {
    let part: Part

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(part.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if !part.serialNumber.isEmpty {
                    Text("SN: \(part.serialNumber)")
                        .font(.caption)
                        .fontDesign(.monospaced)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "$%.2f", part.cost))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                if part.isUnderWarranty {
                    Text("Under Warranty")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct RemindersSection: View {
    let reminders: [ServiceReminder]
    let currentMileage: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Service Reminders")
                .font(.headline)

            if reminders.isEmpty {
                EmptyStateView(
                    icon: "bell.fill",
                    title: "No Reminders",
                    message: "Service reminders will appear here"
                )
            } else {
                ForEach(reminders.filter { !$0.isCompleted }) { reminder in
                    ReminderRow(reminder: reminder, currentMileage: currentMileage)
                }
            }
        }
    }
}

struct ReminderRow: View {
    let reminder: ServiceReminder
    let currentMileage: Int

    var isDue: Bool {
        reminder.isDue(currentMileage: currentMileage)
    }

    var isApproaching: Bool {
        reminder.isApproaching(currentMileage: currentMileage)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if let targetMileage = reminder.targetMileage {
                    Text("Due at \(targetMileage) mi")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if isDue {
                Text("DUE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else if isApproaching {
                Text("SOON")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding()
        .background(isDue ? Color.red.opacity(0.1) : (isApproaching ? Color.orange.opacity(0.1) : Color(.systemGray6)))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Vehicle.self, configurations: config)
    let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2020, currentMileage: 45000)
    container.mainContext.insert(vehicle)

    return NavigationStack {
        VehicleDetailView(vehicle: vehicle)
    }
    .modelContainer(container)
}
