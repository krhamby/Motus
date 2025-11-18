//
//  PartDetailView.swift
//  Motus
//
//  Detailed view of a part
//

import SwiftUI

struct PartDetailView: View {
    let part: Part
    @State private var showingEdit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(part.name)
                        .font(.title)
                        .fontWeight(.bold)

                    if !part.brand.isEmpty {
                        Text(part.brand)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label(part.partCategory.rawValue, systemImage: "folder")
                        Spacer()
                        Label(part.partCondition.rawValue, systemImage: "checkmark.seal")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Part Numbers
                if !part.partNumber.isEmpty || !part.serialNumber.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Part Numbers")
                            .font(.headline)

                        if !part.partNumber.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Part Number")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(part.partNumber)
                                    .font(.subheadline)
                                    .fontDesign(.monospaced)
                                    .textSelection(.enabled)
                            }
                        }

                        if !part.serialNumber.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Serial Number")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(part.serialNumber)
                                    .font(.subheadline)
                                    .fontDesign(.monospaced)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Cost Information
                VStack(alignment: .leading, spacing: 12) {
                    Text("Cost Information")
                        .font(.headline)

                    HStack {
                        Text("Unit Cost")
                        Spacer()
                        Text(String(format: "$%.2f", part.cost))
                            .fontWeight(.semibold)
                    }

                    if part.quantity > 1 {
                        HStack {
                            Text("Quantity")
                            Spacer()
                            Text("\(part.quantity)")
                        }

                        HStack {
                            Text("Total Cost")
                            Spacer()
                            Text(String(format: "$%.2f", part.totalCost))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.accent)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Purchase Details
                VStack(alignment: .leading, spacing: 12) {
                    Text("Purchase Details")
                        .font(.headline)

                    LabeledContent("Purchase Date", value: part.purchaseDate.formatted(date: .long, time: .omitted))

                    if !part.supplier.isEmpty {
                        LabeledContent("Supplier", value: part.supplier)
                    }

                    if let vehicle = part.vehicle {
                        LabeledContent("Vehicle", value: vehicle.displayName)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Installation Details
                if part.installationDate != nil || part.installationMileage != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Installation Details")
                            .font(.headline)

                        if let date = part.installationDate {
                            LabeledContent("Installed On", value: date.formatted(date: .long, time: .omitted))
                        }

                        if let mileage = part.installationMileage {
                            LabeledContent("Installation Mileage", value: "\(mileage) mi")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Warranty Information
                if part.warrantyMonths != nil || part.warrantyMiles != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Warranty Information")
                                .font(.headline)
                            Spacer()
                            if part.isUnderWarranty {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundStyle(.green)
                            }
                        }

                        if let months = part.warrantyMonths {
                            LabeledContent("Duration", value: "\(months) months")
                        }

                        if let miles = part.warrantyMiles {
                            LabeledContent("Mileage Coverage", value: "\(miles) miles")
                        }

                        if let expiration = part.warrantyExpiration {
                            LabeledContent("Expires", value: expiration.formatted(date: .long, time: .omitted))

                            if part.isUnderWarranty {
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
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Notes
                if !part.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notes")
                            .font(.headline)
                        Text(part.notes)
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
            AddEditPartView(part: part)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Part.self, configurations: config)
    let part = Part(
        name: "Oil Filter",
        partNumber: "PF48E",
        serialNumber: "ABC123456",
        brand: "Fram",
        category: .filters,
        cost: 12.99
    )
    container.mainContext.insert(part)

    return NavigationStack {
        PartDetailView(part: part)
    }
    .modelContainer(container)
}
