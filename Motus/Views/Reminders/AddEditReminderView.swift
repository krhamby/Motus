//
//  AddEditReminderView.swift
//  Motus
//
//  Form to add or edit service reminders
//

import SwiftUI
import SwiftData

struct AddEditReminderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var vehicles: [Vehicle]

    var reminder: ServiceReminder?

    @State private var selectedVehicle: Vehicle?
    @State private var title = ""
    @State private var serviceType = MaintenanceType.oilChange
    @State private var reminderType = ReminderType.both
    @State private var targetMileage = ""
    @State private var targetDate: Date?
    @State private var hasTargetDate = false
    @State private var mileageInterval = ""
    @State private var timeInterval = ""
    @State private var notifyInAdvance = true
    @State private var advanceMileage = "500"
    @State private var advanceDays = "7"
    @State private var notes = ""

    var isEditing: Bool {
        reminder != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Reminder Title", text: $title)

                    Picker("Vehicle", selection: $selectedVehicle) {
                        Text("Select Vehicle").tag(nil as Vehicle?)
                        ForEach(vehicles) { vehicle in
                            Text(vehicle.displayName).tag(vehicle as Vehicle?)
                        }
                    }

                    Picker("Service Type", selection: $serviceType) {
                        ForEach(MaintenanceType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }

                Section("Reminder Trigger") {
                    Picker("Remind Based On", selection: $reminderType) {
                        ForEach(ReminderType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    if reminderType == .mileageBased || reminderType == .both {
                        HStack {
                            Text("Target Mileage")
                            Spacer()
                            TextField("0", text: $targetMileage)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                            Text("mi")
                                .foregroundStyle(.secondary)
                        }
                    }

                    if reminderType == .timeBased || reminderType == .both {
                        Toggle("Set Target Date", isOn: $hasTargetDate)

                        if hasTargetDate {
                            DatePicker("Target Date", selection: Binding(
                                get: { targetDate ?? Date() },
                                set: { targetDate = $0 }
                            ), displayedComponents: .date)
                        }
                    }
                }

                Section("Recurring Intervals (Optional)") {
                    if reminderType == .mileageBased || reminderType == .both {
                        HStack {
                            Text("Every")
                            Spacer()
                            TextField("Optional", text: $mileageInterval)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                            Text("miles")
                                .foregroundStyle(.secondary)
                        }
                    }

                    if reminderType == .timeBased || reminderType == .both {
                        HStack {
                            Text("Every")
                            Spacer()
                            TextField("Optional", text: $timeInterval)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                            Text("months")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Advance Notification") {
                    Toggle("Notify in Advance", isOn: $notifyInAdvance)

                    if notifyInAdvance {
                        if reminderType == .mileageBased || reminderType == .both {
                            HStack {
                                Text("Advance Miles")
                                Spacer()
                                TextField("500", text: $advanceMileage)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 100)
                                Text("mi")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if reminderType == .timeBased || reminderType == .both {
                            HStack {
                                Text("Advance Days")
                                Spacer()
                                TextField("7", text: $advanceDays)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 100)
                                Text("days")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(isEditing ? "Edit Reminder" : "Add Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveReminder()
                    }
                    .disabled(selectedVehicle == nil || title.isEmpty)
                }
            }
            .onAppear {
                if let reminder = reminder {
                    loadReminderData(reminder)
                } else {
                    if vehicles.count == 1 {
                        selectedVehicle = vehicles.first
                    }
                    // Set default title based on service type
                    updateTitle()
                }
            }
            .onChange(of: serviceType) { _, _ in
                if title.isEmpty || MaintenanceType.allCases.map { $0.rawValue }.contains(title) {
                    updateTitle()
                }
            }
        }
    }

    private func updateTitle() {
        title = serviceType.rawValue
    }

    private func loadReminderData(_ reminder: ServiceReminder) {
        selectedVehicle = reminder.vehicle
        title = reminder.title
        serviceType = reminder.maintenanceType
        reminderType = reminder.type
        if let mileage = reminder.targetMileage {
            targetMileage = String(mileage)
        }
        targetDate = reminder.targetDate
        hasTargetDate = reminder.targetDate != nil
        if let interval = reminder.mileageInterval {
            mileageInterval = String(interval)
        }
        if let interval = reminder.timeInterval {
            timeInterval = String(interval)
        }
        notifyInAdvance = reminder.notifyInAdvance
        if let advance = reminder.advanceMileage {
            advanceMileage = String(advance)
        }
        if let advance = reminder.advanceDays {
            advanceDays = String(advance)
        }
        notes = reminder.notes
    }

    private func saveReminder() {
        let targetMileageValue = Int(targetMileage)
        let mileageIntervalValue = Int(mileageInterval)
        let timeIntervalValue = Int(timeInterval)
        let advanceMileageValue = Int(advanceMileage)
        let advanceDaysValue = Int(advanceDays)

        if let reminder = reminder {
            // Update existing reminder
            reminder.title = title
            reminder.serviceType = serviceType.rawValue
            reminder.reminderType = reminderType.rawValue
            reminder.targetMileage = targetMileageValue
            reminder.targetDate = hasTargetDate ? targetDate : nil
            reminder.mileageInterval = mileageIntervalValue
            reminder.timeInterval = timeIntervalValue
            reminder.notifyInAdvance = notifyInAdvance
            reminder.advanceMileage = advanceMileageValue
            reminder.advanceDays = advanceDaysValue
            reminder.notes = notes
        } else {
            // Create new reminder
            let newReminder = ServiceReminder(
                title: title,
                serviceType: serviceType,
                reminderType: reminderType,
                targetMileage: targetMileageValue,
                targetDate: hasTargetDate ? targetDate : nil,
                mileageInterval: mileageIntervalValue,
                timeInterval: timeIntervalValue,
                notifyInAdvance: notifyInAdvance,
                advanceMileage: advanceMileageValue,
                advanceDays: advanceDaysValue,
                notes: notes
            )
            newReminder.vehicle = selectedVehicle
            modelContext.insert(newReminder)
        }

        dismiss()
    }
}

#Preview {
    AddEditReminderView()
        .modelContainer(for: ServiceReminder.self, inMemory: true)
}
