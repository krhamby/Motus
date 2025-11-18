//
//  AddEditPartView.swift
//  Motus
//
//  Form to add or edit parts
//

import SwiftUI
import SwiftData

struct AddEditPartView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var vehicles: [Vehicle]

    var part: Part?

    @State private var selectedVehicle: Vehicle?
    @State private var name = ""
    @State private var partNumber = ""
    @State private var serialNumber = ""
    @State private var brand = ""
    @State private var category = PartCategory.other
    @State private var condition = PartCondition.new
    @State private var cost = ""
    @State private var quantity = 1
    @State private var purchaseDate = Date()
    @State private var installationDate: Date?
    @State private var hasInstallationDate = false
    @State private var installationMileage = ""
    @State private var supplier = ""
    @State private var warrantyMonths = ""
    @State private var warrantyMiles = ""
    @State private var notes = ""

    var isEditing: Bool {
        part != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Part Name", text: $name)

                    Picker("Vehicle", selection: $selectedVehicle) {
                        Text("Select Vehicle").tag(nil as Vehicle?)
                        ForEach(vehicles) { vehicle in
                            Text(vehicle.displayName).tag(vehicle as Vehicle?)
                        }
                    }

                    Picker("Category", selection: $category) {
                        ForEach(PartCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }

                    Picker("Condition", selection: $condition) {
                        ForEach(PartCondition.allCases, id: \.self) { cond in
                            Text(cond.rawValue).tag(cond)
                        }
                    }
                }

                Section("Part Numbers") {
                    TextField("Part Number", text: $partNumber)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()

                    TextField("Serial Number", text: $serialNumber)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }

                Section("Purchase Details") {
                    TextField("Brand", text: $brand)

                    HStack {
                        Text("Unit Cost")
                        Spacer()
                        Text("$")
                        TextField("0.00", text: $cost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...999)

                    if quantity > 1 {
                        HStack {
                            Text("Total Cost")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "$%.2f", (Double(cost) ?? 0) * Double(quantity)))
                                .fontWeight(.semibold)
                        }
                    }

                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)

                    TextField("Supplier", text: $supplier)
                }

                Section("Installation") {
                    Toggle("Set Installation Date", isOn: $hasInstallationDate)

                    if hasInstallationDate {
                        DatePicker("Installation Date", selection: Binding(
                            get: { installationDate ?? Date() },
                            set: { installationDate = $0 }
                        ), displayedComponents: .date)

                        HStack {
                            Text("Installation Mileage")
                            Spacer()
                            TextField("Optional", text: $installationMileage)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                            Text("mi")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Warranty") {
                    HStack {
                        Text("Warranty Duration")
                        Spacer()
                        TextField("0", text: $warrantyMonths)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("months")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Warranty Mileage")
                        Spacer()
                        TextField("0", text: $warrantyMiles)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("mi")
                            .foregroundStyle(.secondary)
                    }

                    if let months = Int(warrantyMonths), months > 0 {
                        let expirationDate = Calendar.current.date(byAdding: .month, value: months, to: purchaseDate)!
                        LabeledContent("Warranty Expires", value: expirationDate.formatted(date: .long, time: .omitted))
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(isEditing ? "Edit Part" : "Add Part")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        savePart()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let part = part {
                    loadPartData(part)
                } else if vehicles.count == 1 {
                    selectedVehicle = vehicles.first
                }
            }
        }
    }

    private func loadPartData(_ part: Part) {
        selectedVehicle = part.vehicle
        name = part.name
        partNumber = part.partNumber
        serialNumber = part.serialNumber
        brand = part.brand
        category = part.partCategory
        condition = part.partCondition
        cost = String(part.cost)
        quantity = part.quantity
        purchaseDate = part.purchaseDate
        installationDate = part.installationDate
        hasInstallationDate = part.installationDate != nil
        if let mileage = part.installationMileage {
            installationMileage = String(mileage)
        }
        supplier = part.supplier
        if let months = part.warrantyMonths {
            warrantyMonths = String(months)
        }
        if let miles = part.warrantyMiles {
            warrantyMiles = String(miles)
        }
        notes = part.notes
    }

    private func savePart() {
        let costValue = Double(cost) ?? 0
        let installMileage = Int(installationMileage)
        let warrantyMo = Int(warrantyMonths)
        let warrantyMi = Int(warrantyMiles)

        if let part = part {
            // Update existing part
            part.name = name
            part.partNumber = partNumber
            part.serialNumber = serialNumber
            part.brand = brand
            part.category = category.rawValue
            part.condition = condition.rawValue
            part.cost = costValue
            part.quantity = quantity
            part.purchaseDate = purchaseDate
            part.installationDate = hasInstallationDate ? installationDate : nil
            part.installationMileage = installMileage
            part.supplier = supplier
            part.warrantyMonths = warrantyMo
            part.warrantyMiles = warrantyMi
            part.notes = notes

            if let months = warrantyMo {
                part.warrantyExpiration = Calendar.current.date(byAdding: .month, value: months, to: purchaseDate)
            }
        } else {
            // Create new part
            let newPart = Part(
                name: name,
                partNumber: partNumber,
                serialNumber: serialNumber,
                brand: brand,
                category: category,
                condition: condition,
                cost: costValue,
                purchaseDate: purchaseDate,
                installationDate: hasInstallationDate ? installationDate : nil,
                installationMileage: installMileage,
                supplier: supplier,
                warrantyMonths: warrantyMo,
                warrantyMiles: warrantyMi,
                notes: notes,
                quantity: quantity
            )
            newPart.vehicle = selectedVehicle
            modelContext.insert(newPart)
        }

        dismiss()
    }
}

#Preview {
    AddEditPartView()
        .modelContainer(for: Part.self, inMemory: true)
}
