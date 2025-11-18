//
//  PartsListView.swift
//  Motus
//
//  Parts inventory with serial number tracking
//

import SwiftUI
import SwiftData

struct PartsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Part.purchaseDate, order: .reverse) private var parts: [Part]
    @Query private var vehicles: [Vehicle]

    @State private var showingAddPart = false
    @State private var selectedVehicle: Vehicle?
    @State private var selectedCategory: PartCategory?
    @State private var searchText = ""
    @State private var showWarrantyOnly = false

    var filteredParts: [Part] {
        var result = parts

        if let vehicle = selectedVehicle {
            result = result.filter { $0.vehicle == vehicle }
        }

        if let category = selectedCategory {
            result = result.filter { $0.partCategory == category }
        }

        if showWarrantyOnly {
            result = result.filter { $0.isUnderWarranty }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.brand.localizedCaseInsensitiveContains(searchText) ||
                $0.serialNumber.localizedCaseInsensitiveContains(searchText) ||
                $0.partNumber.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    var totalInventoryValue: Double {
        filteredParts.reduce(0) { $0 + $1.totalCost }
    }

    var partsUnderWarranty: Int {
        filteredParts.filter { $0.isUnderWarranty }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Summary
                if !filteredParts.isEmpty {
                    HStack(spacing: 20) {
                        VStack(alignment: .leading) {
                            Text("Total Value")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(String(format: "$%.2f", totalInventoryValue))
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Parts")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(filteredParts.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        if partsUnderWarranty > 0 {
                            VStack(alignment: .trailing) {
                                Text("Under Warranty")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("\(partsUnderWarranty)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.green)
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
                            FilterButton(
                                icon: "car.fill",
                                text: selectedVehicle?.displayName ?? "All Vehicles",
                                isActive: selectedVehicle != nil
                            )
                        }

                        Menu {
                            Button("All Categories") {
                                selectedCategory = nil
                            }
                            ForEach(PartCategory.allCases, id: \.self) { category in
                                Button(category.rawValue) {
                                    selectedCategory = category
                                }
                            }
                        } label: {
                            FilterButton(
                                icon: "folder.fill",
                                text: selectedCategory?.rawValue ?? "All Categories",
                                isActive: selectedCategory != nil
                            )
                        }

                        Button {
                            showWarrantyOnly.toggle()
                        } label: {
                            FilterButton(
                                icon: "checkmark.shield.fill",
                                text: "Warranty",
                                isActive: showWarrantyOnly
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)

                // Parts List
                if filteredParts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "gearshape.2.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("No Parts")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Add parts to track your inventory and warranties")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredParts) { part in
                            NavigationLink(destination: PartDetailView(part: part)) {
                                PartRowView(part: part)
                            }
                        }
                        .onDelete(perform: deleteParts)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Parts Inventory")
            .searchable(text: $searchText, prompt: "Search parts, serial numbers...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddPart = true
                    } label: {
                        Label("Add Part", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPart) {
                AddEditPartView()
            }
        }
    }

    private func deleteParts(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredParts[index])
            }
        }
    }
}

struct FilterButton: View {
    let icon: String
    let text: String
    let isActive: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(text)
            Image(systemName: "chevron.down")
        }
        .font(.subheadline)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isActive ? Color.accentColor : Color(.systemGray5))
        .foregroundStyle(isActive ? .white : .primary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct PartRowView: View {
    let part: Part

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(part.name)
                    .font(.headline)
                Spacer()
                Text(String(format: "$%.2f", part.totalCost))
                    .font(.headline)
                    .foregroundStyle(.accent)
            }

            if !part.brand.isEmpty {
                Text(part.brand)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack {
                if !part.serialNumber.isEmpty {
                    Label("SN: \(part.serialNumber)", systemImage: "number")
                        .font(.caption)
                        .fontDesign(.monospaced)
                        .foregroundStyle(.secondary)
                }
                if !part.partNumber.isEmpty {
                    Label("PN: \(part.partNumber)", systemImage: "barcode")
                        .font(.caption)
                        .fontDesign(.monospaced)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Label(part.partCategory.rawValue, systemImage: "folder")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if part.isUnderWarranty {
                    Spacer()
                    Label("Warranty", systemImage: "checkmark.shield.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    PartsListView()
        .modelContainer(for: Part.self, inMemory: true)
}
