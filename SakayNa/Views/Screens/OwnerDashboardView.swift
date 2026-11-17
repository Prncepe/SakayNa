import SwiftUI

struct OwnerDashboardView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var vehicles: VehicleController
    @EnvironmentObject private var bookings: BookingController
    @Binding var path: NavigationPath

    var body: some View {
        ZStack {
            palette.canvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    AppHeader()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Good morning, \(auth.user.firstName)")
                            .font(.system(size: 14))
                            .foregroundStyle(palette.muted)
                        Text("Your fleet is moving")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(palette.text)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(value: AppFormat.peso(bookings.totalEarnings), label: "Monthly earnings")
                        StatCard(value: "\(bookings.activeBookingCount)", label: "Active bookings")
                        StatCard(value: "\(vehicles.listedVehicles(ownerId: auth.user.id).count)", label: "Listed vehicles")
                        StatCard(value: "\(bookings.pendingRequestCount)", label: "New requests")
                    }

                    HStack(spacing: 12) {
                        OutlineButton(title: "Booking Requests") {
                            bookings.selectedTab = .bookings
                        }
                        PrimaryButton(title: "Add Vehicle", systemImage: "plus") {
                            vehicles.beginAddVehicle()
                            path.append(AppRoute.addVehicle)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Earnings this month")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(palette.text)
                        if bookings.isLoading && bookings.bookings.isEmpty {
                            LoadingStateView(message: "Loading earnings…", compact: true)
                        } else if bookings.monthlyCompletedBookings.isEmpty {
                            Text("No completed bookings this month yet.")
                                .font(.system(size: 13))
                                .foregroundStyle(palette.muted)
                        } else {
                            ForEach(bookings.monthlyCompletedBookings) { booking in
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(booking.vehicle.name)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(palette.text)
                                        Text("\(booking.renterName) · \(AppFormat.shortDate(booking.endDate))")
                                            .font(.system(size: 12))
                                            .foregroundStyle(palette.muted)
                                    }
                                    Spacer()
                                    Text(AppFormat.peso(booking.totalPrice))
                                        .font(.system(size: 15, weight: .heavy))
                                        .foregroundStyle(palette.text)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(palette.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(palette.border, lineWidth: 1)
                    )

                    HStack {
                        Text("Your vehicles")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(palette.text)
                        Spacer()
                    }

                    let listed = vehicles.listedVehicles(ownerId: auth.user.id)
                    if vehicles.isLoading && vehicles.vehicles.isEmpty {
                        LoadingStateView(message: "Loading your vehicles…")
                    } else if listed.isEmpty {
                        EmptyStateView(
                            systemImage: "car",
                            title: "No vehicles listed",
                            message: "Tap Add Vehicle to list a motorcycle or car."
                        )
                    } else {
                        ForEach(listed) { vehicle in
                            VStack(alignment: .leading, spacing: 10) {
                                VehicleCardView(vehicle: vehicle, showsFavorite: false) {
                                    vehicles.beginEditVehicle(vehicle)
                                    path.append(AppRoute.addVehicle)
                                }
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(vehicle.isActive ? "Active" : "Inactive")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(palette.text)
                                        Text("Listing visibility")
                                            .font(.system(size: 11))
                                            .foregroundStyle(palette.muted)
                                    }
                                    AppToggle(isOn: vehicle.isActive) {
                                        vehicles.toggleActive(id: vehicle.id)
                                    }
                                    Spacer()
                                    OutlineButton(title: "Edit") {
                                        vehicles.beginEditVehicle(vehicle)
                                        path.append(AppRoute.addVehicle)
                                    }
                                    .frame(width: 110)
                                }
                            }
                        }
                    }
                }
                .padding(24)
                .padding(.bottom, 88)
            }
        }
        .navigationBarHidden(true)
        .alert("Can't activate listing", isPresented: Binding(
            get: { vehicles.listingAlert != nil },
            set: { if !$0 { vehicles.listingAlert = nil } }
        )) {
            Button("OK", role: .cancel) { vehicles.listingAlert = nil }
        } message: {
            Text(vehicles.listingAlert ?? "")
        }
    }
}
