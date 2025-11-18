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
                        // Vehicle Selector
                        if vehicles.count > 1 {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    Button {
                                        selectedVehicle = nil
                                    } label: {
                                        VehicleSelectorCard(
                                            title: "All Vehicles",
                                            subtitle: "\(vehicles.count) vehicles",
                                            isSelected: selectedVehicle == nil
                                        )
                                    }

                                    ForEach(vehicles) { vehicle in
                                        Button {
                                            selectedVehicle = vehicle
                                        } label: {
                                            VehicleSelectorCard(
                                                title: vehicle.displayName,
                                                subtitle: "\(vehicle.currentMileage) mi",
                                                isSelected: selectedVehicle == vehicle
                                            )
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        } else if let vehicle = vehicles.first {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(vehicle.displayName)
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text("\(vehicle.currentMileage) miles")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                        }

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
                                subtitle: "\(filteredMaintenanceRecords.count) records",
                                icon: "wrench.fill",
                                color: .orange
                            )

                            DashboardCard(
                                title: "Fuel Cost",
                                value: String(format: "$%.0f", totalFuelCost),
                                subtitle: "\(filteredFuelLogs.count) fill-ups",
                                icon: "fuelpump.fill",
                                color: .red
                            )

                            DashboardCard(
                                title: "Avg MPG",
                                value: String(format: "%.1f", averageMPG),
                                subtitle: "miles per gallon",
                                icon: "gauge.high",
                                color: .green
                            )

                            DashboardCard(
                                title: "Parts",
                                value: "\(selectedVehicle?.parts.count ?? vehicles.reduce(0) { $0 + $1.parts.count })",
                                subtitle: "in inventory",
                                icon: "gearshape.2.fill",
                                color: .blue
                            )
                        }
                        .padding(.horizontal)

                        // Fuel Price Trend
                        if filteredFuelLogs.count >= 3 {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Fuel Price Trend (Last 10)")
                                    .font(.headline)
                                    .padding(.horizontal)

                                Chart(filteredFuelLogs.sorted { $0.date < $1.date }.suffix(10)) { log in
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
                        if filteredMaintenanceRecords.count >= 3 {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Maintenance Spending (Last 10)")
                                    .font(.headline)
                                    .padding(.horizontal)

                                Chart(filteredMaintenanceRecords.sorted { $0.date < $1.date }.suffix(10)) { record in
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

                            if filteredMaintenanceRecords.isEmpty && filteredFuelLogs.isEmpty {
                                Text("No activity yet")
                                    .foregroundStyle(.secondary)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                            } else {
                                ForEach(recentActivity().prefix(5)) { item in
                                    ActivityRow(item: item)
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
                if vehicles.count == 1 {
                    selectedVehicle = vehicles.first
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
