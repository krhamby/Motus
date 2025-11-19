//
//  LocationMapPreview.swift
//  Motus
//
//  Created by Claude on 11/19/25.
//

import SwiftUI
import MapKit

struct LocationMapPreview: View {
    let businessName: String
    let latitude: Double
    let longitude: Double
    let tintColor: Color

    @State private var position: MapCameraPosition

    init(businessName: String, latitude: Double, longitude: Double, tintColor: Color = .blue) {
        self.businessName = businessName
        self.latitude = latitude
        self.longitude = longitude
        self.tintColor = tintColor

        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(tintColor)
                    .font(.title3)
                Text("Location")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 12)

            Map(position: $position, interactionModes: []) {
                Marker(businessName, coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                    .tint(tintColor)
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    LocationMapPreview(
        businessName: "Joe's Auto Repair",
        latitude: 37.7749,
        longitude: -122.4194,
        tintColor: .blue
    )
    .padding()
}
