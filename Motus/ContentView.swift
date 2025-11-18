//
//  ContentView.swift
//  Motus
//
//  Created by Kevin Hamby on 10/7/25.
//

import Charts
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                HStack {
                    Text("Dashboard")
                        .font(.largeTitle)
                        .bold()
                        .padding()

                    Spacer()
                }

                HStack {
                    Card()
                    Card()
                }
                .padding(.horizontal)

                Chart {
                    BarMark(
                        x: .value("Trip", 1),
                        y: .value("Miles", 25)
                    )
                    BarMark(
                        x: .value("Trip", 2),
                        y: .value("Miles", 13)
                    )
                }
                .padding()
                .frame(height: 250)

                HStack {
                    Card()
                    Card()
                }
                .padding(.horizontal)

                HStack {
                    Card()
                    Card()
                }
                .padding(.horizontal)

                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text("Dashboard")
                            .font(.largeTitle)
                            .bold()
                        Spacer()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        // Edit action
                    }
                }
            }
        }
    }
}

struct Card: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Title")
                    .font(.title)

                Spacer()
            }

            Spacer()

            HStack {
                Text("Body")

                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.all)
        .background(Color(.systemGray5))
        .frame(height: 125)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
