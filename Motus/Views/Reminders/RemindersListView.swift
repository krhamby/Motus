//
//  RemindersListView.swift
//  Motus
//
//  Service reminders management
//

import SwiftUI
import SwiftData

struct RemindersListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var reminders: [ServiceReminder]
    @Query private var vehicles: [Vehicle]

    @State private var showingAddReminder = false
    @State private var selectedVehicle: Vehicle?

    var filteredReminders: [ServiceReminder] {
        if let vehicle = selectedVehicle {
            return reminders.filter { $0.vehicle == vehicle }
        }
        return reminders
    }

    var activeReminders: [ServiceReminder] {
        filteredReminders.filter { !$0.isCompleted }
    }

    var completedReminders: [ServiceReminder] {
        filteredReminders.filter { $0.isCompleted }
    }

    var body: some View {
        NavigationStack {
            List {
                if !activeReminders.isEmpty {
                    Section("Active Reminders") {
                        ForEach(activeReminders.sorted { reminder1, reminder2 in
                            let vehicle1Mileage = reminder1.vehicle?.currentMileage ?? 0
                            let vehicle2Mileage = reminder2.vehicle?.currentMileage ?? 0
                            let due1 = reminder1.isDue(currentMileage: vehicle1Mileage)
                            let due2 = reminder2.isDue(currentMileage: vehicle2Mileage)
                            if due1 != due2 {
                                return due1
                            }
                            return (reminder1.targetMileage ?? Int.max) < (reminder2.targetMileage ?? Int.max)
                        }) { reminder in
                            ReminderRowView(reminder: reminder)
                        }
                        .onDelete(perform: deleteReminders)
                    }
                }

                if !completedReminders.isEmpty {
                    Section("Completed") {
                        ForEach(completedReminders) { reminder in
                            ReminderRowView(reminder: reminder)
                        }
                        .onDelete(perform: deleteCompletedReminders)
                    }
                }

                if filteredReminders.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("No Service Reminders")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Create reminders for upcoming maintenance")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Service Reminders")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if vehicles.count > 1 {
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
                            HStack {
                                Text(selectedVehicle?.displayName ?? "All")
                                Image(systemName: "chevron.down")
                            }
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddReminder = true
                    } label: {
                        Label("Add Reminder", systemImage: "plus")
                    }
                    .disabled(vehicles.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddReminder) {
                AddEditReminderView()
            }
        }
    }

    private func deleteReminders(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(activeReminders[index])
            }
        }
    }

    private func deleteCompletedReminders(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(completedReminders[index])
            }
        }
    }
}

struct ReminderRowView: View {
    @Environment(\.modelContext) private var modelContext
    let reminder: ServiceReminder

    var currentMileage: Int {
        reminder.vehicle?.currentMileage ?? 0
    }

    var isDue: Bool {
        reminder.isDue(currentMileage: currentMileage)
    }

    var isApproaching: Bool {
        reminder.isApproaching(currentMileage: currentMileage)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(reminder.title)
                    .font(.headline)
                    .strikethrough(reminder.isCompleted)

                if let vehicle = reminder.vehicle {
                    Label(vehicle.displayName, systemImage: "car.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    if let targetMileage = reminder.targetMileage {
                        Label("\(targetMileage) mi", systemImage: "gauge")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let targetDate = reminder.targetDate {
                        Label(targetDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if !reminder.isCompleted {
                if isDue {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("DUE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        Button {
                            completeReminder()
                        } label: {
                            Text("Mark Done")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                } else if isApproaching {
                    Text("SOON")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }

    private func completeReminder() {
        withAnimation {
            reminder.isCompleted = true
            reminder.completedDate = Date()
        }
    }
}

#Preview {
    RemindersListView()
        .modelContainer(for: ServiceReminder.self, inMemory: true)
}
