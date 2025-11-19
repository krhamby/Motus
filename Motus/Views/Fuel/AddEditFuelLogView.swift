//
//  AddEditFuelLogView.swift
//  Motus
//
//  Form to add or edit fuel logs
//

import SwiftUI
import SwiftData
import MapKit

struct AddEditFuelLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var vehicles: [Vehicle]
    @Query(sort: \FuelLog.date, order: .reverse) private var allLogs: [FuelLog]

    var log: FuelLog?

    @State private var selectedVehicle: Vehicle?
    @State private var date = Date()
    @State private var mileage = ""
    @State private var gallons = ""
    @State private var pricePerGallon = ""
    @State private var location = ""
    @State private var fuelGrade = FuelGrade.regular
    @State private var fullTank = true
    @State private var octaneRating = ""
    @State private var notes = ""

    // Location data
    @State private var locationLatitude: Double?
    @State private var locationLongitude: Double?
    @State private var locationAddress: String?
    @State private var showingMapPicker = false

    var isEditing: Bool {
        log != nil
    }

    var calculatedTotal: Double {
        let gal = Double(gallons) ?? 0
        let price = Double(pricePerGallon) ?? 0
        return gal * price
    }

    var calculatedMPG: Double? {
        guard fullTank,
              let vehicle = selectedVehicle,
              let currentMileage = Int(mileage),
              let gal = Double(gallons),
              gal > 0 else {
            return nil
        }

        // Find the previous fuel log for this vehicle
        let vehicleLogs = allLogs.filter { $0.vehicle == vehicle && $0.fullTank }
        if let previousLog = vehicleLogs.first(where: { $0.mileage < currentMileage }) {
            let miles = currentMileage - previousLog.mileage
            return miles > 0 ? Double(miles) / gal : nil
        }

        return nil
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

                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])

                    HStack {
                        Text("Odometer")
                        Spacer()
                        TextField("0", text: $mileage)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("mi")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Fuel Details") {
                    HStack {
                        Text("Gallons")
                        Spacer()
                        TextField("0.00", text: $gallons)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("gal")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Price per Gallon")
                        Spacer()
                        Text("$")
                        TextField("0.00", text: $pricePerGallon)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    HStack {
                        Text("Total Cost")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "$%.2f", calculatedTotal))
                            .fontWeight(.semibold)
                    }

                    Picker("Fuel Grade", selection: $fuelGrade) {
                        ForEach(FuelGrade.allCases, id: \.self) { grade in
                            Text(grade.rawValue).tag(grade)
                        }
                    }

                    HStack {
                        Text("Octane Rating")
                        Spacer()
                        TextField("Optional", text: $octaneRating)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    Toggle("Full Tank", isOn: $fullTank)
                }

                if let mpg = calculatedMPG {
                    Section {
                        HStack {
                            Label("Calculated MPG", systemImage: "gauge.high")
                                .foregroundStyle(.green)
                            Spacer()
                            Text(String(format: "%.1f", mpg))
                                .fontWeight(.semibold)
                                .foregroundStyle(.green)
                        }
                    }
                }

                Section("Location") {
                    HStack {
                        TextField("Gas Station or Location", text: $location)
                        Button(action: {
                            showingMapPicker = true
                        }) {
                            Image(systemName: "map.fill")
                                .foregroundStyle(.white)
                                .font(.system(size: 14, weight: .semibold))
                                .frame(width: 32, height: 32)
                                .background(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: .orange.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                    }

                    if let address = locationAddress {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                            Text(address)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(isEditing ? "Edit Fuel Log" : "Add Fuel Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveLog()
                    }
                    .disabled(selectedVehicle == nil || mileage.isEmpty || gallons.isEmpty || pricePerGallon.isEmpty)
                }
            }
            .onAppear {
                if let log = log {
                    loadLogData(log)
                } else if vehicles.count == 1 {
                    selectedVehicle = vehicles.first
                    if let vehicle = selectedVehicle {
                        mileage = String(vehicle.currentMileage)
                    }
                }
            }
            .sheet(isPresented: $showingMapPicker) {
                LocationMapPicker(
                    selectedName: $location,
                    selectedLatitude: $locationLatitude,
                    selectedLongitude: $locationLongitude,
                    selectedAddress: $locationAddress,
                    searchCategory: "Gas Station"
                )
            }
        }
    }

    private func loadLogData(_ log: FuelLog) {
        selectedVehicle = log.vehicle
        date = log.date
        mileage = String(log.mileage)
        gallons = String(log.gallons)
        pricePerGallon = String(log.pricePerGallon)
        location = log.location
        fuelGrade = log.grade
        fullTank = log.fullTank
        if let octane = log.octaneRating {
            octaneRating = String(octane)
        }
        notes = log.notes
        locationLatitude = log.locationLatitude
        locationLongitude = log.locationLongitude
        locationAddress = log.locationAddress
    }

    private func saveLog() {
        let mileageValue = Int(mileage) ?? 0
        let gallonsValue = Double(gallons) ?? 0
        let priceValue = Double(pricePerGallon) ?? 0
        let octaneValue = Int(octaneRating)

        if let log = log {
            // Update existing log
            log.date = date
            log.mileage = mileageValue
            log.gallons = gallonsValue
            log.pricePerGallon = priceValue
            log.totalCost = gallonsValue * priceValue
            log.location = location
            log.fuelGrade = fuelGrade.rawValue
            log.fullTank = fullTank
            log.octaneRating = octaneValue
            log.notes = notes
            log.mpg = calculatedMPG
            log.locationLatitude = locationLatitude
            log.locationLongitude = locationLongitude
            log.locationAddress = locationAddress
        } else {
            // Create new log
            let newLog = FuelLog(
                date: date,
                mileage: mileageValue,
                gallons: gallonsValue,
                pricePerGallon: priceValue,
                location: location,
                fuelGrade: fuelGrade,
                fullTank: fullTank,
                notes: notes,
                octaneRating: octaneValue,
                locationLatitude: locationLatitude,
                locationLongitude: locationLongitude,
                locationAddress: locationAddress
            )
            newLog.vehicle = selectedVehicle
            newLog.mpg = calculatedMPG
            modelContext.insert(newLog)

            // Update vehicle's current mileage if this is higher
            if let vehicle = selectedVehicle, mileageValue > vehicle.currentMileage {
                vehicle.currentMileage = mileageValue
            }
        }

        dismiss()
    }
}

#Preview {
    AddEditFuelLogView()
        .modelContainer(for: FuelLog.self, inMemory: true)
}
