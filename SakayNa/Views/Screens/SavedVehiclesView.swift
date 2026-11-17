import SwiftUI

struct SavedVehiclesView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var vehicles: VehicleController
    @Binding var path: NavigationPath

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AppHeader(title: "Saved Vehicles", showsBack: true, showsProfileActions: false) {
                    if !path.isEmpty { path.removeLast() }
                }

                if vehicles.isLoading && vehicles.vehicles.isEmpty {
                    LoadingStateView(message: "Loading saved vehicles…")
                } else if vehicles.savedVehicles.isEmpty {
                    EmptyStateView(
                        systemImage: "heart",
                        title: "No saved vehicles",
                        message: "Tap the heart on a listing to save it here."
                    )
                } else {
                    VStack(spacing: 16) {
                        ForEach(vehicles.savedVehicles) { vehicle in
                            VehicleCardView(vehicle: vehicle) {
                                vehicles.select(vehicle)
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
}
