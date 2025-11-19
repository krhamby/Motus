//
//  DashboardView.swift
//  Motus
//
//  Enhanced dashboard with real data and analytics
//

import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var vehicles: [Vehicle]
    @Query(sort: \MaintenanceRecord.date, order: .reverse) private var maintenanceRecords: [MaintenanceRecord]
    @Query(sort: \FuelLog.date, order: .reverse) private var fuelLogs: [FuelLog]
    @Query private var serviceReminders: [ServiceReminder]

    @State private var selectedVehicle: Vehicle?
    @State private var showingAddVehicle = false
    @State private var expandedVehicles: Set<PersistentIdentifier> = []

    var filteredMaintenanceRecords: [MaintenanceRecord] {
        guard let vehicle = selectedVehicle else { return maintenanceRecords }
        return maintenanceRecords.filter { $0.vehicle == vehicle }
    }

    var filteredFuelLogs: [FuelLog] {
        guard let vehicle = selectedVehicle else { return fuelLogs }
        return fuelLogs.filter { $0.vehicle == vehicle }
    }

    var filteredReminders: [ServiceReminder] {
        guard let vehicle = selectedVehicle else { return serviceReminders }
        return serviceReminders.filter { $0.vehicle == vehicle }
    }

    var totalMaintenanceCost: Double {
        filteredMaintenanceRecords.reduce(0) { $0 + $1.cost }
    }

    var totalFuelCost: Double {
        filteredFuelLogs.reduce(0) { $0 + $1.totalCost }
    }

    var averageMPG: Double {
        guard let vehicle = selectedVehicle else {
            return vehicles.reduce(0) { $0 + $1.averageMPG } / Double(max(vehicles.count, 1))
        }
        return vehicle.averageMPG
    }

    var dueReminders: [ServiceReminder] {
        guard let vehicle = selectedVehicle else {
            return serviceReminders.filter { reminder in
                if let v = reminder.vehicle {
                    return reminder.isDue(currentMileage: v.currentMileage)
                }
                return false
            }
        }
        return filteredReminders.filter { $0.isDue(currentMileage: vehicle.currentMileage) }
    }

    var approachingReminders: [ServiceReminder] {
        guard let vehicle = selectedVehicle else {
            return serviceReminders.filter { reminder in
                if let v = reminder.vehicle {
                    return reminder.isApproaching(currentMileage: v.currentMileage)
                }
                return false
            }
        }
        return filteredReminders.filter { $0.isApproaching(currentMileage: vehicle.currentMileage) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if vehicles.isEmpty {
                        // Empty State
                        VStack(spacing: 20) {
                            Image(systemName: "car.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                            Text("Welcome to Motus")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Your complete car maintenance tracker")
                                .foregroundStyle(.secondary)
                            Text("Add your first vehicle to start tracking maintenance, fuel, and parts")
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            Button {
                                showingAddVehicle = true
                            } label: {
                                Label("Add Your First Vehicle", systemImage: "plus")
                                    .padding()
                                    .background(Color.accentColor)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                    } else {
                        // Collapsible Vehicle Sections
                        ForEach(vehicles) { vehicle in
                            CollapsibleVehicleSection(
                                vehicle: vehicle,
                                isExpanded: expandedVehicles.contains(vehicle.persistentModelID),
                                maintenanceRecords: maintenanceRecords.filter { $0.vehicle == vehicle },
                                fuelLogs: fuelLogs.filter { $0.vehicle == vehicle },
                                serviceReminders: serviceReminders.filter { $0.vehicle == vehicle },
                                showDetailedSummary: vehicles.count >= 3
                            ) {
                                if expandedVehicles.contains(vehicle.persistentModelID) {
                                    expandedVehicles.remove(vehicle.persistentModelID)
                                } else {
                                    expandedVehicles.insert(vehicle.persistentModelID)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .toolbar {
                if !vehicles.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingAddVehicle = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddVehicle) {
                AddEditVehicleView()
            }
            .onAppear {
                // Auto-expand single vehicle
                if vehicles.count == 1, let vehicle = vehicles.first {
                    expandedVehicles.insert(vehicle.persistentModelID)
                }
            }
        }
    }

    func recentActivity() -> [ActivityItem] {
        var items: [ActivityItem] = []

        items += filteredMaintenanceRecords.prefix(10).map { record in
            ActivityItem(
                id: record.persistentModelID.hashValue,
                date: record.date,
                title: record.maintenanceType.rawValue,
                subtitle: String(format: "$%.2f at %d mi", record.cost, record.mileage),
                icon: "wrench.fill",
                color: .orange
            )
        }

        items += filteredFuelLogs.prefix(10).map { log in
            ActivityItem(
                id: log.persistentModelID.hashValue,
                date: log.date,
                title: "Fuel Purchase",
                subtitle: String(format: "%.1f gal - $%.2f", log.gallons, log.totalCost),
                icon: "fuelpump.fill",
                color: .blue
            )
        }

        return items.sorted { $0.date > $1.date }
    }
}

struct CollapsibleVehicleSection: View {
    let vehicle: Vehicle
    let isExpanded: Bool
    let maintenanceRecords: [MaintenanceRecord]
    let fuelLogs: [FuelLog]
    let serviceReminders: [ServiceReminder]
    let showDetailedSummary: Bool
    let onToggle: () -> Void

    var totalMaintenanceCost: Double {
        maintenanceRecords.reduce(0) { $0 + $1.cost }
    }

    var totalFuelCost: Double {
        fuelLogs.reduce(0) { $0 + $1.totalCost }
    }

    var dueReminders: [ServiceReminder] {
        serviceReminders.filter { $0.isDue(currentMileage: vehicle.currentMileage) }
    }

    var approachingReminders: [ServiceReminder] {
        serviceReminders.filter { $0.isApproaching(currentMileage: vehicle.currentMileage) }
    }

    var nextServiceAlert: ServiceReminder? {
        dueReminders.first ?? approachingReminders.first
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header (always visible)
            Button(action: onToggle) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vehicle.displayName)
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("\(vehicle.currentMileage) miles")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                .padding()
                .background(Color(.systemGray6))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Collapsed Summary (shown when collapsed and 3+ cars)
            if !isExpanded && showDetailedSummary {
                VStack(alignment: .leading, spacing: 12) {
                    // Service Alert if any
                    if let alert = nextServiceAlert {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(dueReminders.contains(alert) ? .red : .orange)
                            Text(alert.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text(dueReminders.contains(alert) ? "DUE" : "SOON")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(dueReminders.contains(alert) ? Color.red : Color.orange)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }

                    // Quick Stats
                    HStack(spacing: 12) {
                        CompactStatView(
                            icon: "wrench.fill",
                            value: String(format: "$%.0f", totalMaintenanceCost),
                            label: "Maintenance",
                            color: .orange
                        )

                        CompactStatView(
                            icon: "fuelpump.fill",
                            value: String(format: "$%.0f", totalFuelCost),
                            label: "Fuel",
                            color: .red
                        )

                        CompactStatView(
                            icon: "gauge.high",
                            value: String(format: "%.1f", vehicle.averageMPG),
                            label: "MPG",
                            color: .green
                        )

                        CompactStatView(
                            icon: "gearshape.2.fill",
                            value: "\(vehicle.parts.count)",
                            label: "Parts",
                            color: .blue
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
                .background(Color(.systemGray6).opacity(0.5))
            }

            // Expanded Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 20) {
                    // Service Alerts
                    if !dueReminders.isEmpty || !approachingReminders.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Service Alerts")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(dueReminders.prefix(3)) { reminder in
                                ServiceAlertCard(reminder: reminder, isDue: true)
                            }

                            ForEach(approachingReminders.prefix(2)) { reminder in
                                ServiceAlertCard(reminder: reminder, isDue: false)
                            }
                        }
                    }

                    // Summary Stats
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        DashboardCard(
                            title: "Maintenance",
                            value: String(format: "$%.0f", totalMaintenanceCost),
                            subtitle: "\(maintenanceRecords.count) records",
                            icon: "wrench.fill",
                            color: .orange
                        )

                        DashboardCard(
                            title: "Fuel Cost",
                            value: String(format: "$%.0f", totalFuelCost),
                            subtitle: "\(fuelLogs.count) fill-ups",
                            icon: "fuelpump.fill",
                            color: .red
                        )

                        DashboardCard(
                            title: "Avg MPG",
                            value: String(format: "%.1f", vehicle.averageMPG),
                            subtitle: "miles per gallon",
                            icon: "gauge.high",
                            color: .green
                        )

                        DashboardCard(
                            title: "Parts",
                            value: "\(vehicle.parts.count)",
                            subtitle: "in inventory",
                            icon: "gearshape.2.fill",
                            color: .blue
                        )
                    }
                    .padding(.horizontal)

                    // Fuel Price Trend
                    if fuelLogs.count >= 3 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Fuel Price Trend (Last 10)")
                                .font(.headline)
                                .padding(.horizontal)

                            Chart(fuelLogs.sorted { $0.date < $1.date }.suffix(10)) { log in
                                LineMark(
                                    x: .value("Date", log.date, unit: .day),
                                    y: .value("Price", log.pricePerGallon)
                                )
                                .foregroundStyle(.blue)
                                .symbol(Circle())
                            }
                            .chartYAxisLabel("$/gal")
                            .frame(height: 200)
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                        .background(Color(.systemGray6))
                    }

                    // Maintenance Spending
                    if maintenanceRecords.count >= 3 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Maintenance Spending (Last 10)")
                                .font(.headline)
                                .padding(.horizontal)

                            Chart(maintenanceRecords.sorted { $0.date < $1.date }.suffix(10)) { record in
                                BarMark(
                                    x: .value("Date", record.date, unit: .day),
                                    y: .value("Cost", record.cost)
                                )
                                .foregroundStyle(.orange)
                            }
                            .chartYAxisLabel("Cost ($)")
                            .frame(height: 200)
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                        .background(Color(.systemGray6))
                    }

                    // Recent Activity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activity")
                            .font(.headline)
                            .padding(.horizontal)

                        if maintenanceRecords.isEmpty && fuelLogs.isEmpty {
                            Text("No activity yet")
                                .foregroundStyle(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity)
                        } else {
                            ForEach(recentActivity(maintenance: maintenanceRecords, fuel: fuelLogs).prefix(5)) { item in
                                ActivityRow(item: item)
                            }
                        }
                    }
                }
                .padding(.vertical)
                .background(Color(.systemBackground))
            }
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    func recentActivity(maintenance: [MaintenanceRecord], fuel: [FuelLog]) -> [ActivityItem] {
        var items: [ActivityItem] = []

        items += maintenance.prefix(10).map { record in
            ActivityItem(
                id: record.persistentModelID.hashValue,
                date: record.date,
                title: record.maintenanceType.rawValue,
                subtitle: String(format: "$%.2f at %d mi", record.cost, record.mileage),
                icon: "wrench.fill",
                color: .orange
            )
        }

        items += fuel.prefix(10).map { log in
            ActivityItem(
                id: log.persistentModelID.hashValue,
                date: log.date,
                title: "Fuel Purchase",
                subtitle: String(format: "%.1f gal - $%.2f", log.gallons, log.totalCost),
                icon: "fuelpump.fill",
                color: .blue
            )
        }

        return items.sorted { $0.date > $1.date }
    }
}

struct CompactStatView: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct VehicleSelectorCard: View {
    let title: String
    let subtitle: String
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 160)
        .background(isSelected ? Color.accentColor : Color(.systemGray6))
        .foregroundStyle(isSelected ? .white : .primary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct DashboardCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
                Spacer()
            }
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ServiceAlertCard: View {
    let reminder: ServiceReminder
    let isDue: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if let mileage = reminder.targetMileage {
                    Text("Due at \(mileage) mi")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(isDue ? "DUE NOW" : "SOON")
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isDue ? Color.red : Color.orange)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding()
        .background(isDue ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
    }
}

struct ActivityItem: Identifiable {
    let id: Int
    let date: Date
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
}

struct ActivityRow: View {
    let item: ActivityItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .foregroundStyle(item.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(item.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: Vehicle.self, inMemory: true)
}
