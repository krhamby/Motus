//
//  AddEditVehicleView.swift
//  Motus
//
//  Form to add or edit a vehicle
//

import SwiftUI
import SwiftData

struct AddEditVehicleView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var vehicle: Vehicle?

    @State private var make = ""
    @State private var model = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var vin = ""
    @State private var licensePlate = ""
    @State private var purchaseDate = Date()
    @State private var currentMileage = 0
    @State private var color = ""
    @State private var engineType = ""
    @State private var transmissionType = "Automatic"
    @State private var notes = ""

    let currentYear = Calendar.current.component(.year, from: Date())
    let transmissionTypes = ["Automatic", "Manual", "CVT", "DCT"]

    var isEditing: Bool {
        vehicle != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Make", text: $make)
                        .autocorrectionDisabled()
                    TextField("Model", text: $model)
                        .autocorrectionDisabled()

                    Picker("Year", selection: $year) {
                        ForEach((1980...currentYear + 1).reversed(), id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }

                    TextField("License Plate", text: $licensePlate)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)

                    TextField("Color", text: $color)
                        .autocorrectionDisabled()
                }

                Section("Details") {
                    TextField("VIN", text: $vin)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)

                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)

                    HStack {
                        Text("Current Mileage")
                        Spacer()
                        TextField("0", value: $currentMileage, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("mi")
                            .foregroundStyle(.secondary)
                    }

                    TextField("Engine Type", text: $engineType)
                        .autocorrectionDisabled()

                    Picker("Transmission", selection: $transmissionType) {
                        ForEach(transmissionTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(isEditing ? "Edit Vehicle" : "Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveVehicle()
                    }
                    .disabled(make.isEmpty || model.isEmpty)
                }
            }
            .onAppear {
                if let vehicle = vehicle {
                    loadVehicleData(vehicle)
                }
            }
        }
    }

    private func loadVehicleData(_ vehicle: Vehicle) {
        make = vehicle.make
        model = vehicle.model
        year = vehicle.year
        vin = vehicle.vin
        licensePlate = vehicle.licensePlate
        purchaseDate = vehicle.purchaseDate
        currentMileage = vehicle.currentMileage
        color = vehicle.color
        engineType = vehicle.engineType
        transmissionType = vehicle.transmissionType
        notes = vehicle.notes
    }

    private func saveVehicle() {
        if let vehicle = vehicle {
            // Update existing vehicle
            vehicle.make = make
            vehicle.model = model
            vehicle.year = year
            vehicle.vin = vin
            vehicle.licensePlate = licensePlate
            vehicle.purchaseDate = purchaseDate
            vehicle.currentMileage = currentMileage
            vehicle.color = color
            vehicle.engineType = engineType
            vehicle.transmissionType = transmissionType
            vehicle.notes = notes
        } else {
            // Create new vehicle
            let newVehicle = Vehicle(
                make: make,
                model: model,
                year: year,
                vin: vin,
                licensePlate: licensePlate,
                purchaseDate: purchaseDate,
                currentMileage: currentMileage,
                color: color,
                engineType: engineType,
                transmissionType: transmissionType,
                notes: notes
            )
            modelContext.insert(newVehicle)
        }

        dismiss()
    }
}

#Preview {
    AddEditVehicleView()
        .modelContainer(for: Vehicle.self, inMemory: true)
}
