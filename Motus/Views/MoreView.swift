//
//  MoreView.swift
//  Motus
//
//  Custom more menu to avoid iOS automatic "More" tab navigation issues
//

import SwiftUI
import SwiftData

struct MoreView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        PartsListView()
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Parts Inventory")
                                    .font(.headline)
                                Text("Track parts and inventory")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "gearshape.2.fill")
                                .foregroundStyle(.blue)
                                .font(.title2)
                        }
                    }

                    NavigationLink {
                        ManualLibraryView(modelContext: modelContext)
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("AI Manual Assistant")
                                    .font(.headline)
                                Text("Ask questions about your car manual")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "brain")
                                .foregroundStyle(.purple)
                                .font(.title2)
                        }
                    }
                }
            }
            .navigationTitle("More")
        }
    }
}

#Preview {
    MoreView()
        .modelContainer(for: Vehicle.self, inMemory: true)
}
