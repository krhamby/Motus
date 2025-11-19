//
//  AddEditMaintenanceView.swift
//  Motus
//
//  Form to add or edit maintenance records
//

import SwiftUI
import SwiftData

struct AddEditMaintenanceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var vehicles: [Vehicle]

    var record: MaintenanceRecord?

    @State private var selectedVehicle: Vehicle?
    @State private var date = Date()
    @State private var type = MaintenanceType.oilChange
    @State private var mileage = ""
    @State private var cost = ""
    @State private var serviceProvider = ""
    @State private var technicianName = ""
    @State private var laborHours = ""
    @State private var notes = ""
    @State private var nextServiceMileage = ""
    @State private var nextServiceDate: Date?
    @State private var hasNextServiceDate = false
    @State private var warrantyExpiration: Date?
    @State private var hasWarranty = false

    var isEditing: Bool {
        record != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    Picker("Vehicle", selection: $selectedVehicle) {
                        Text("Select Vehicle").tag(nil as Vehicle?)
                        ForEach(vehicles) { vehicle in
                            Text(vehicle.displayName).tag(vehicle as Vehicle?)
                        }
                    }

                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    Picker("Service Type", selection: $type) {
                        ForEach(MaintenanceType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    HStack {
                        Text("Mileage")
                        Spacer()
                        TextField("0", text: $mileage)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("mi")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Cost Details") {
                    HStack {
                        Text("Total Cost")
                        Spacer()
                        Text("$")
                        TextField("0.00", text: $cost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    HStack {
                        Text("Labor Hours")
                        Spacer()
                        TextField("0.0", text: $laborHours)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("hrs")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Service Provider") {
                    TextField("Business Name", text: $serviceProvider)
                    TextField("Technician Name", text: $technicianName)
                }

                Section("Next Service") {
                    HStack {
                        Text("Next Service Mileage")
                        Spacer()
                        TextField("Optional", text: $nextServiceMileage)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("mi")
                            .foregroundStyle(.secondary)
                    }

                    Toggle("Set Next Service Date", isOn: $hasNextServiceDate)
                    if hasNextServiceDate {
                        DatePicker("Next Service Date", selection: Binding(
                            get: { nextServiceDate ?? Date() },
                            set: { nextServiceDate = $0 }
                        ), displayedComponents: .date)
                    }
                }

                Section("Warranty") {
                    Toggle("Has Warranty", isOn: $hasWarranty)
                    if hasWarranty {
                        DatePicker("Warranty Expiration", selection: Binding(
                            get: { warrantyExpiration ?? Date() },
                            set: { warrantyExpiration = $0 }
                        ), displayedComponents: .date)
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(isEditing ? "Edit Maintenance" : "Add Maintenance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveRecord()
                    }
                    .disabled(selectedVehicle == nil || mileage.isEmpty)
                }
            }
            .onAppear {
                if let record = record {
                    loadRecordData(record)
                } else if vehicles.count == 1 {
                    selectedVehicle = vehicles.first
                }
            }
        }
    }

    private func loadRecordData(_ record: MaintenanceRecord) {
        selectedVehicle = record.vehicle
        date = record.date
        type = record.maintenanceType
        mileage = String(record.mileage)
        cost = String(record.cost)
        serviceProvider = record.serviceProvider
        technicianName = record.technicianName
        laborHours = String(record.laborHours)
        notes = record.notes
        if let nextMileage = record.nextServiceMileage {
            nextServiceMileage = String(nextMileage)
        }
        nextServiceDate = record.nextServiceDate
        hasNextServiceDate = record.nextServiceDate != nil
        warrantyExpiration = record.warrantyExpiration
        hasWarranty = record.warrantyExpiration != nil
    }

    private func saveRecord() {
        let mileageValue = Int(mileage) ?? 0
        let costValue = Double(cost) ?? 0
        let laborValue = Double(laborHours) ?? 0
        let nextMileageValue = Int(nextServiceMileage)

        if let record = record {
            // Update existing record
            record.date = date
            record.type = type.rawValue
            record.mileage = mileageValue
            record.cost = costValue
            record.serviceProvider = serviceProvider
            record.technicianName = technicianName
            record.laborHours = laborValue
            record.notes = notes
            record.nextServiceMileage = nextMileageValue
            record.nextServiceDate = hasNextServiceDate ? nextServiceDate : nil
            record.warrantyExpiration = hasWarranty ? warrantyExpiration : nil
        } else {
            // Create new record
            let newRecord = MaintenanceRecord(
                date: date,
                type: type,
                mileage: mileageValue,
                cost: costValue,
                serviceProvider: serviceProvider,
                technicianName: technicianName,
                laborHours: laborValue,
                notes: notes,
                nextServiceMileage: nextMileageValue,
                nextServiceDate: hasNextServiceDate ? nextServiceDate : nil,
                warrantyExpiration: hasWarranty ? warrantyExpiration : nil
            )
            newRecord.vehicle = selectedVehicle
            modelContext.insert(newRecord)

            // Update vehicle's current mileage if this is higher
            if let vehicle = selectedVehicle, mileageValue > vehicle.currentMileage {
                vehicle.currentMileage = mileageValue
            }
        }

        dismiss()
    }
}

#Preview {
    AddEditMaintenanceView()
        .modelContainer(for: MaintenanceRecord.self, inMemory: true)
}
