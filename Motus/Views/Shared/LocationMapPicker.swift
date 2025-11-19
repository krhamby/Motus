//
//  LocationMapPicker.swift
//  Motus
//
//  Created by Claude on 11/19/25.
//

import SwiftUI
import MapKit

struct BusinessLocation: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let category: String

    static func == (lhs: BusinessLocation, rhs: BusinessLocation) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct LocationMapPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedName: String
    @Binding var selectedLatitude: Double?
    @Binding var selectedLongitude: Double?
    @Binding var selectedAddress: String?

    let searchCategory: String // e.g., "Auto Repair" or "Gas Station"

    @State private var searchText = ""
    @State private var position: MapCameraPosition = .automatic
    @State private var searchResults: [BusinessLocation] = []
    @State private var selectedLocation: BusinessLocation?
    @State private var isSearching = false
    @State private var currentRegion: MKCoordinateRegion?
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ZStack {
                // Map View
                Map(position: $position, selection: $selectedLocation) {
                    ForEach(searchResults) { location in
                        Marker(location.name, coordinate: location.coordinate)
                            .tint(.blue)
                            .tag(location)
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }
                .onMapCameraChange { context in
                    currentRegion = context.region

                    // Cancel any pending search
                    searchTask?.cancel()

                    // Debounce: Search after 0.5 seconds of no movement
                    searchTask = Task {
                        try? await Task.sleep(nanoseconds: 500_000_000)

                        guard !Task.isCancelled else { return }
                        await searchInVisibleRegion(context.region)
                    }
                }

                // Search indicator at top
                VStack {
                    if isSearching {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Searching this area...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 4)
                        .padding(.top, 8)
                    }
                    Spacer()
                }

                // Search results card overlay
                VStack {
                    Spacer()

                    if !searchResults.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Tap a location on the map or select below:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                                .padding(.top, 12)
                                .padding(.bottom, 8)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(searchResults) { location in
                                        LocationCard(location: location, isSelected: selectedLocation?.id == location.id)
                                            .onTapGesture {
                                                withAnimation {
                                                    selectedLocation = location
                                                    position = .region(MKCoordinateRegion(
                                                        center: location.coordinate,
                                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                                    ))
                                                }
                                            }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 12)
                            }
                        }
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 10)
                        .padding()
                    }
                }
            }
            .navigationTitle("Select \(searchCategory)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Select") {
                        if let selected = selectedLocation {
                            selectedName = selected.name
                            selectedLatitude = selected.coordinate.latitude
                            selectedLongitude = selected.coordinate.longitude
                            selectedAddress = selected.address
                        }
                        dismiss()
                    }
                    .disabled(selectedLocation == nil)
                    .fontWeight(.semibold)
                }
            }
            .searchable(text: $searchText, prompt: "Search for \(searchCategory.lowercased())")
            .onSubmit(of: .search) {
                performSearch()
            }
            .onChange(of: searchText) { oldValue, newValue in
                // If user clears the search, search the visible region
                if !oldValue.isEmpty && newValue.isEmpty, let region = currentRegion {
                    Task {
                        await searchInVisibleRegion(region)
                    }
                }
            }
            .onChange(of: selectedLocation) { _, newValue in
                if let location = newValue {
                    withAnimation {
                        position = .region(MKCoordinateRegion(
                            center: location.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        ))
                    }
                }
            }
            .task {
                // Initial search for nearby locations
                await searchNearbyLocations()
            }
        }
    }

    private func performSearch() {
        Task {
            await searchLocations(query: searchText)
        }
    }

    private func searchNearbyLocations() async {
        isSearching = true

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchCategory
        request.resultTypes = .pointOfInterest

        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()

            await MainActor.run {
                searchResults = response.mapItems.prefix(10).map { item in
                    BusinessLocation(
                        name: item.name ?? "Unknown",
                        address: formatAddress(item.placemark),
                        coordinate: item.placemark.coordinate,
                        category: item.pointOfInterestCategory?.rawValue ?? searchCategory
                    )
                }

                // Set initial camera position to show all results
                if let firstResult = searchResults.first {
                    position = .region(MKCoordinateRegion(
                        center: firstResult.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    ))
                }

                isSearching = false
            }
        } catch {
            print("Search error: \(error)")
            isSearching = false
        }
    }

    private func searchLocations(query: String) async {
        guard !query.isEmpty else {
            await searchNearbyLocations()
            return
        }

        isSearching = true

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest

        // Use current region if available
        if let region = currentRegion {
            request.region = region
        }

        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()

            await MainActor.run {
                searchResults = response.mapItems.prefix(15).map { item in
                    BusinessLocation(
                        name: item.name ?? "Unknown",
                        address: formatAddress(item.placemark),
                        coordinate: item.placemark.coordinate,
                        category: item.pointOfInterestCategory?.rawValue ?? searchCategory
                    )
                }

                if let firstResult = searchResults.first {
                    position = .region(MKCoordinateRegion(
                        center: firstResult.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                    ))
                }

                isSearching = false
            }
        } catch {
            print("Search error: \(error)")
            isSearching = false
        }
    }

    private func searchInVisibleRegion(_ region: MKCoordinateRegion) async {
        // Don't search if user is actively typing in the search bar
        guard searchText.isEmpty else { return }

        isSearching = true

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchCategory
        request.resultTypes = .pointOfInterest
        request.region = region

        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()

            await MainActor.run {
                searchResults = response.mapItems.prefix(15).map { item in
                    BusinessLocation(
                        name: item.name ?? "Unknown",
                        address: formatAddress(item.placemark),
                        coordinate: item.placemark.coordinate,
                        category: item.pointOfInterestCategory?.rawValue ?? searchCategory
                    )
                }

                isSearching = false
            }
        } catch {
            print("Search error: \(error)")
            isSearching = false
        }
    }

    private func formatAddress(_ placemark: MKPlacemark) -> String {
        var components: [String] = []

        if let street = placemark.thoroughfare {
            components.append(street)
        }
        if let city = placemark.locality {
            components.append(city)
        }
        if let state = placemark.administrativeArea {
            components.append(state)
        }

        return components.joined(separator: ", ")
    }
}

struct LocationCard: View {
    let location: BusinessLocation
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(isSelected ? .white : .blue)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(location.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(isSelected ? .white : .primary)
                        .lineLimit(1)

                    Text(location.address)
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.9) : .secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: 240)
        .background(isSelected ? Color.blue : Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.clear : Color(.systemGray4), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var name = ""
        @State private var latitude: Double? = nil
        @State private var longitude: Double? = nil
        @State private var address: String? = nil

        var body: some View {
            LocationMapPicker(
                selectedName: $name,
                selectedLatitude: $latitude,
                selectedLongitude: $longitude,
                selectedAddress: $address,
                searchCategory: "Auto Repair"
            )
        }
    }

    return PreviewWrapper()
}
