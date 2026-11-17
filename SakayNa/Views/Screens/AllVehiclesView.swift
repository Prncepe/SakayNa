import SwiftUI

struct AllVehiclesView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var vehicles: VehicleController
    @EnvironmentObject private var bookings: BookingController
    @Binding var path: NavigationPath

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AppHeader(title: "All Vehicles", showsBack: true) {
                    path.removeLast()
                }
                if vehicles.isLoading && vehicles.vehicles.isEmpty {
                    LoadingStateView(message: "Loading vehicles…")
                } else if displayedVehicles.isEmpty {
                    EmptyStateView(
                        systemImage: "car",
                        title: "No vehicles found",
                        message: "There are no listings to show right now."
                    )
                } else {
                    VStack(spacing: 16) {
                        ForEach(displayedVehicles) { vehicle in
                            VehicleCardView(
                                vehicle: vehicle,
                                availabilityLabel: bookings.availabilityLabel
                            ) {
                                vehicles.select(vehicle)
                                if bookings.availabilityFilterOn {
                                    vehicles.days = bookings.rentalDays
                                }
                                path.append(AppRoute.vehicleDetail(vehicle.id))
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(palette.canvas.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private var displayedVehicles: [Vehicle] {
        vehicles.sortedVehicles.filter { bookings.isVehicleAvailable($0) }
    }
}
