import SwiftUI

struct HomeView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var vehicles: VehicleController
    @EnvironmentObject private var bookings: BookingController
    @Binding var path: NavigationPath
    @FocusState private var searchFocused: Bool

    var body: some View {
        ZStack {
            palette.canvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    AppHeader()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hi, \(auth.user.firstName)")
                            .font(.system(size: 14))
                            .foregroundStyle(palette.muted)
                        Text("Where to?")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(palette.text)
                    }

                    HStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(palette.muted)
                            TextField("Search vehicles or city", text: $vehicles.searchQuery)
                                .focused($searchFocused)
                                .font(.system(size: 15))
                                .foregroundStyle(palette.text)
                        }
                        .padding(.horizontal, 18)
                        .frame(height: 54)
                        .background(palette.fieldFill)
                        .overlay(Capsule().stroke(palette.border, lineWidth: 1))
                        .clipShape(Capsule())

                        IconCircleButton(systemName: "slider.horizontal.3") {
                            vehicles.showFilters = true
                        }
                    }

                    HomeAvailabilityBar()

                    HStack(spacing: 8) {
                        ForEach(VehicleFilter.allCases, id: \.self) { filter in
                            FilterChip(
                                title: filter.rawValue,
                                isActive: vehicles.category == filter
                            ) {
                                vehicles.category = filter
                            }
                        }
                    }

                    HStack {
                        Text("Popular near you")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(palette.text)
                        Spacer()
                        Menu {
                            ForEach(VehicleSort.allCases, id: \.self) { option in
                                Button {
                                    vehicles.sortOption = option
                                } label: {
                                    if vehicles.sortOption == option {
                                        Label(option.rawValue, systemImage: "checkmark")
                                    } else {
                                        Text(option.rawValue)
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(vehicles.sortOption.rawValue)
                                Image(systemName: "chevron.down")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(palette.muted)
                        }
                        Button("See all") {
                            path.append(AppRoute.allVehicles)
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(palette.muted)
                    }

                    if vehicles.isLoading && vehicles.vehicles.isEmpty {
                        LoadingStateView(message: "Loading vehicles…")
                    } else if bookings.isCheckingAvailability && displayedVehicles.isEmpty {
                        LoadingStateView(message: "Checking availability…")
                    } else if displayedVehicles.isEmpty {
                        EmptyStateView(
                            systemImage: "magnifyingglass",
                            title: "No vehicles found",
                            message: "Try different dates, a city, search, or sort."
                        )
                    } else {
                        VStack(spacing: 16) {
                            ForEach(displayedVehicles) { vehicle in
                                VehicleCardView(
                                    vehicle: vehicle,
                                    availabilityLabel: bookings.availabilityLabel
                                ) {
                                    openDetail(vehicle)
                                }
                            }
                        }
                    }
                }
                .padding(24)
                .padding(.bottom, 88)
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .navigationBarHidden(true)
        .onChange(of: vehicles.focusSearch) { _, focused in
            if focused {
                searchFocused = true
                vehicles.focusSearch = false
            }
        }
        .sheet(isPresented: $vehicles.showFilters) {
            filterSheet
        }
    }

    private var displayedVehicles: [Vehicle] {
        vehicles.sortedVehicles.filter { bookings.isVehicleAvailable($0) }
    }

    private func openDetail(_ vehicle: Vehicle) {
        vehicles.select(vehicle)
        if bookings.availabilityFilterOn {
            vehicles.days = bookings.rentalDays
        }
        path.append(AppRoute.vehicleDetail(vehicle.id))
    }

    private var filterSheet: some View {
        NavigationStack {
            Form {
                Section("Max price (₱)") {
                    TextField("e.g. 1000", text: $vehicles.filterMaxPriceText)
                        .keyboardType(.numberPad)
                }
                Section("Vehicle type") {
                    Picker("Type", selection: $vehicles.category) {
                        ForEach(VehicleFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .scrollContentBackground(.hidden)
            .background(palette.canvas)
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { vehicles.showFilters = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") { vehicles.applyFilters() }
                        .foregroundStyle(palette.yellow)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
