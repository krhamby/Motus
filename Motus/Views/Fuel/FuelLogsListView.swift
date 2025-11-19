//
//  FuelLogsListView.swift
//  Motus
//
//  Fuel purchase tracking and analysis
//

import SwiftUI
import SwiftData
import Charts

struct FuelLogsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FuelLog.date, order: .reverse) private var fuelLogs: [FuelLog]
    @Query private var vehicles: [Vehicle]

    @State private var showingAddLog = false
    @State private var selectedVehicle: Vehicle?
    @State private var showingCharts = false

    var filteredLogs: [FuelLog] {
        if let vehicle = selectedVehicle {
            return fuelLogs.filter { $0.vehicle == vehicle }
        }
        return fuelLogs
    }

    var totalSpent: Double {
        filteredLogs.reduce(0) { $0 + $1.totalCost }
    }

    var totalGallons: Double {
        filteredLogs.reduce(0) { $0 + $1.gallons }
    }

    var averagePricePerGallon: Double {
        guard !filteredLogs.isEmpty else { return 0 }
        return totalSpent / totalGallons
    }

    var averageMPG: Double {
        guard filteredLogs.count > 1 else { return 0 }
        let sortedLogs = filteredLogs.sorted { $0.date < $1.date }.filter { $0.fullTank }

        var totalMPG = 0.0
        var count = 0

        for i in 1..<sortedLogs.count {
            let milesDriven = Double(sortedLogs[i].mileage - sortedLogs[i-1].mileage)
            let gallons = sortedLogs[i].gallons
            if gallons > 0 && milesDriven > 0 {
                totalMPG += milesDriven / gallons
                count += 1
            }
        }

        return count > 0 ? totalMPG / Double(count) : 0
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Summary Stats
                if !filteredLogs.isEmpty {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        FuelStatCard(title: "Total Spent", value: String(format: "$%.2f", totalSpent), icon: "dollarsign.circle.fill", color: .red)
                        FuelStatCard(title: "Avg Price/Gal", value: String(format: "$%.2f", averagePricePerGallon), icon: "fuelpump.fill", color: .blue)
                        FuelStatCard(title: "Total Gallons", value: String(format: "%.1f", totalGallons), icon: "drop.fill", color: .orange)
                        if averageMPG > 0 {
                            FuelStatCard(title: "Avg MPG", value: String(format: "%.1f", averageMPG), icon: "gauge.high", color: .green)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)

                    // Price Trend Chart
                    if filteredLogs.count >= 2 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Price per Gallon Trend")
                                .font(.headline)
                                .padding(.horizontal)

                            Chart(filteredLogs.sorted { $0.date < $1.date }.suffix(10)) { log in
                                LineMark(
                                    x: .value("Date", log.date),
                                    y: .value("Price", log.pricePerGallon)
                                )
                                .foregroundStyle(.blue)
                                .symbol(Circle())

                                PointMark(
                                    x: .value("Date", log.date),
                                    y: .value("Price", log.pricePerGallon)
                                )
                                .foregroundStyle(.blue)
                            }
                            .chartYAxisLabel("$/gal")
                            .frame(height: 150)
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                        .background(Color(.systemGray6))
                    }
                }

                // Vehicle Filter
                if vehicles.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            Button {
                                selectedVehicle = nil
                            } label: {
                                Text("All Vehicles")
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(selectedVehicle == nil ? Color.accentColor : Color(.systemGray5))
                                    .foregroundStyle(selectedVehicle == nil ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }

                            ForEach(vehicles) { vehicle in
                                Button {
                                    selectedVehicle = vehicle
                                } label: {
                                    Text(vehicle.displayName)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(selectedVehicle == vehicle ? Color.accentColor : Color(.systemGray5))
                                        .foregroundStyle(selectedVehicle == vehicle ? .white : .primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }

                // Logs List
                if filteredLogs.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "fuelpump.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("No Fuel Logs")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Add fuel purchases to track prices and fuel economy")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredLogs) { log in
                            NavigationLink(destination: FuelLogDetailView(log: log)) {
                                FuelLogCell(log: log)
                            }
                        }
                        .onDelete(perform: deleteLogs)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Fuel Logs")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddLog = true
                    } label: {
                        Label("Add Log", systemImage: "plus")
                    }
                    .disabled(vehicles.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddLog) {
                AddEditFuelLogView()
            }
        }
    }

    private func deleteLogs(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredLogs[index])
            }
        }
    }
}

struct FuelStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
    }
}

struct FuelLogCell: View {
    let log: FuelLog

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(String(format: "%.2f", log.gallons)) gal")
                    .font(.headline)
                Spacer()
                Text(String(format: "$%.2f", log.totalCost))
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)
            }

            HStack {
                if let vehicle = log.vehicle {
                    Label(vehicle.displayName, systemImage: "car.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Label("\(log.mileage) mi", systemImage: "gauge")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                if !log.location.isEmpty {
                    Label(log.location, systemImage: "mappin.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Text(String(format: "$%.2f/gal", log.pricePerGallon))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("•")
                    .foregroundStyle(.secondary)
                Text(log.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let mpg = log.mpg {
                HStack {
                    Image(systemName: "gauge.high")
                        .font(.caption2)
                    Text(String(format: "%.1f MPG", mpg))
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FuelLogsListView()
        .modelContainer(for: FuelLog.self, inMemory: true)
}
