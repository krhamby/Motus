//
//  MaintenanceDetailView.swift
//  Motus
//
//  Detailed view of a maintenance record
//

import SwiftUI
import SwiftData

struct MaintenanceDetailView: View {
    let record: MaintenanceRecord
    @State private var showingEdit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(record.maintenanceType.rawValue)
                        .font(.title)
                        .fontWeight(.bold)

                    if let vehicle = record.vehicle {
                        Text(vehicle.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("\(record.mileage) mi", systemImage: "gauge")
                        Spacer()
                        Label(record.date.formatted(date: .long, time: .omitted), systemImage: "calendar")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Cost Breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("Cost Breakdown")
                        .font(.headline)

                    HStack {
                        Text("Total Cost")
                        Spacer()
                        Text(String(format: "$%.2f", record.cost))
                            .fontWeight(.semibold)
                    }

                    if record.partsCost > 0 {
                        HStack {
                            Text("Parts")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "$%.2f", record.partsCost))
                        }
                    }

                    if record.laborCost > 0 {
                        HStack {
                            Text("Labor")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "$%.2f", record.laborCost))
                        }
                    }

                    if record.laborHours > 0 {
                        HStack {
                            Text("Labor Hours")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.1f hrs", record.laborHours))
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Service Provider
                if !record.serviceProvider.isEmpty || !record.technicianName.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Service Provider")
                            .font(.headline)

                        if !record.serviceProvider.isEmpty {
                            LabeledContent("Business", value: record.serviceProvider)
                        }

                        if !record.technicianName.isEmpty {
                            LabeledContent("Technician", value: record.technicianName)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Parts Used
                if !record.partsUsed.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Parts Used (\(record.partsUsed.count))")
                            .font(.headline)

                        ForEach(record.partsUsed) { part in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(part.name)
                                        .font(.subheadline)
                                    if !part.partNumber.isEmpty {
                                        Text("PN: \(part.partNumber)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Text(String(format: "$%.2f", part.cost))
                                    .font(.subheadline)
                            }
                            Divider()
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Next Service
                if record.nextServiceMileage != nil || record.nextServiceDate != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Next Service")
                            .font(.headline)

                        if let nextMileage = record.nextServiceMileage {
                            LabeledContent("At Mileage", value: "\(nextMileage) mi")
                        }

                        if let nextDate = record.nextServiceDate {
                            LabeledContent("By Date", value: nextDate.formatted(date: .long, time: .omitted))
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Warranty
                if let warranty = record.warrantyExpiration {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Warranty")
                            .font(.headline)

                        LabeledContent("Expires", value: warranty.formatted(date: .long, time: .omitted))

                        if warranty > Date() {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Under Warranty")
                                    .foregroundStyle(.green)
                            }
                            .font(.subheadline)
                        } else {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.orange)
                                Text("Warranty Expired")
                                    .foregroundStyle(.orange)
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Notes
                if !record.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notes")
                            .font(.headline)
                        Text(record.notes)
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
            AddEditMaintenanceView(record: record)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: MaintenanceRecord.self, configurations: config)
    let record = MaintenanceRecord(type: .oilChange, mileage: 50000, cost: 45.99)
    container.mainContext.insert(record)

    return NavigationStack {
        MaintenanceDetailView(record: record)
    }
    .modelContainer(container)
}
