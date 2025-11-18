//
//  ReportsView.swift
//  Motus
//
//  Export and share vehicle reports
//

import SwiftUI
import SwiftData

struct ReportsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var vehicles: [Vehicle]

    @State private var selectedVehicle: Vehicle?
    @State private var selectedReportType: ReportType = .combined
    @State private var showingShareSheet = false
    @State private var reportURL: URL?

    enum ReportType: String, CaseIterable {
        case maintenance = "Maintenance Report"
        case fuel = "Fuel Report"
        case combined = "Complete Report"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Select Vehicle") {
                    Picker("Vehicle", selection: $selectedVehicle) {
                        Text("Select Vehicle").tag(nil as Vehicle?)
                        ForEach(vehicles) { vehicle in
                            Text(vehicle.displayName).tag(vehicle as Vehicle?)
                        }
                    }
                }

                if selectedVehicle != nil {
                    Section("Report Type") {
                        Picker("Type", selection: $selectedReportType) {
                            ForEach(ReportType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section {
                        Button {
                            generateAndShareReport()
                        } label: {
                            Label("Generate & Share Report", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }

                    if let vehicle = selectedVehicle {
                        Section("Preview") {
                            ScrollView {
                                Text(getReportPreview(for: vehicle))
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                            .frame(maxHeight: 300)
                        }
                    }
                }
            }
            .navigationTitle("Reports")
            .sheet(isPresented: $showingShareSheet) {
                if let url = reportURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private func getReportPreview(for vehicle: Vehicle) -> String {
        switch selectedReportType {
        case .maintenance:
            return ReportGenerator.generateMaintenanceReport(for: vehicle)
        case .fuel:
            return ReportGenerator.generateFuelReport(for: vehicle)
        case .combined:
            return ReportGenerator.generateCombinedReport(for: vehicle)
        }
    }

    private func generateAndShareReport() {
        guard let vehicle = selectedVehicle else { return }

        let report = getReportPreview(for: vehicle)
        let filename = "\(vehicle.make)_\(vehicle.model)_\(selectedReportType.rawValue.replacingOccurrences(of: " ", with: "_"))_\(Date().formatted(date: .numeric, time: .omitted)).txt"

        if let url = report.saveAsTextFile(filename: filename) {
            reportURL = url
            showingShareSheet = true
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ReportsView()
        .modelContainer(for: Vehicle.self, inMemory: true)
}
