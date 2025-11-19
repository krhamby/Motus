//
//  FuelLogDetailView.swift
//  Motus
//
//  Detailed view of a fuel log
//

import SwiftUI
import SwiftData

struct FuelLogDetailView: View {
    let log: FuelLog
    @State private var showingEdit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(String(format: "%.2f", log.gallons))
                            .font(.title)
                            .fontWeight(.bold)
                        Text("gallons")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    if let vehicle = log.vehicle {
                        Text(vehicle.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("\(log.mileage) mi", systemImage: "gauge")
                        Spacer()
                        Label(log.date.formatted(date: .long, time: .shortened), systemImage: "calendar.badge.clock")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Cost Details
                VStack(alignment: .leading, spacing: 12) {
                    Text("Cost Details")
                        .font(.headline)

                    HStack {
                        Text("Price per Gallon")
                        Spacer()
                        Text(String(format: "$%.2f", log.pricePerGallon))
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("Total Cost")
                        Spacer()
                        Text(String(format: "$%.2f", log.totalCost))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Fuel Details
                VStack(alignment: .leading, spacing: 12) {
                    Text("Fuel Details")
                        .font(.headline)

                    LabeledContent("Grade", value: log.grade.rawValue)

                    if let octane = log.octaneRating {
                        LabeledContent("Octane", value: String(octane))
                    }

                    LabeledContent("Fill Type", value: log.fullTank ? "Full Tank" : "Partial Fill")
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Fuel Economy
                if let mpg = log.mpg {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Fuel Economy")
                            .font(.headline)

                        HStack {
                            Image(systemName: "gauge.high")
                                .font(.title)
                                .foregroundStyle(.green)
                            VStack(alignment: .leading) {
                                Text(String(format: "%.1f", mpg))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.green)
                                Text("Miles per Gallon")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Location
                if !log.location.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Location")
                            .font(.headline)

                        Label(log.location, systemImage: "mappin.circle.fill")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Notes
                if !log.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notes")
                            .font(.headline)
                        Text(log.notes)
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingEdit = true
                } label: {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddEditFuelLogView(log: log)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FuelLog.self, configurations: config)
    let log = FuelLog(mileage: 45000, gallons: 12.5, pricePerGallon: 3.45, location: "Shell Gas Station")
    container.mainContext.insert(log)

    return NavigationStack {
        FuelLogDetailView(log: log)
    }
    .modelContainer(container)
}
