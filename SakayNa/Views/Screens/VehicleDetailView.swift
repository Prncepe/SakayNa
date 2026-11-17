import SwiftUI

struct VehicleDetailView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var vehicles: VehicleController
    @EnvironmentObject private var bookings: BookingController
    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var messages: MessageController
    @Binding var path: NavigationPath

    var body: some View {
        Group {
            if let vehicle = vehicles.selectedVehicle {
                detail(for: vehicle)
            } else {
                Text("Vehicle unavailable")
                    .foregroundStyle(palette.muted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(palette.canvas)
            }
        }
        .navigationBarHidden(true)
    }

    private func detail(for vehicle: Vehicle) -> some View {
        ZStack(alignment: .bottom) {
            palette.canvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    hero(for: vehicle)
                    infoCard(for: vehicle)
                    specsGrid(for: vehicle)
                    extras(for: vehicle)
                    reviews(for: vehicle)
                    if auth.user.role == .renter {
                        OutlineButton(title: "Message Owner") {
                            let conversation = messages.startOrFind(
                                renterId: auth.user.id,
                                ownerId: vehicle.ownerId,
                                vehicleId: vehicle.id
                            )
                            path.append(AppRoute.chat(conversation.id))
                        }
                    }
                    moreLikeThis(for: vehicle)
                    Color.clear.frame(height: 108)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }

            bottomBar(for: vehicle)
        }
    }

    private func hero(for vehicle: Vehicle) -> some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                Spacer()
                ZStack {
                    Ellipse()
                        .fill(palette.text.opacity(0.14))
                        .frame(width: 240, height: 28)
                    Circle()
                        .fill(palette.yellow)
                        .frame(width: 8, height: 8)
                        .offset(y: 10)
                    VehicleGalleryView(vehicle: vehicle, height: 170)
                        .offset(y: -18)
                }
                .frame(height: 200)
            }
            HStack {
                IconCircleButton(systemName: "chevron.left") {
                    if !path.isEmpty { path.removeLast() }
                }
                Spacer()
                IconCircleButton(systemName: vehicles.isFavorite ? "heart.fill" : "heart") {
                    vehicles.toggleFavorite()
                }
            }
            .padding(.top, 8)
        }
        .frame(height: 250)
    }

    private func infoCard(for vehicle: Vehicle) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(vehicle.name)
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(palette.text)
            Text("\(vehicle.brand) · \(vehicle.type.rawValue)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(palette.muted)
            if auth.user(id: vehicle.ownerId)?.isVerifiedOwner == true {
                VerifiedOwnerBadge()
            }
            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                Text(vehicle.location)
            }
            .font(.system(size: 13))
            .foregroundStyle(palette.muted)
            if !vehicle.description.isEmpty {
                Text(vehicle.description)
                    .font(.system(size: 14))
                    .foregroundStyle(palette.text.opacity(0.85))
            }
        }
    }

    private func specsGrid(for vehicle: Vehicle) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(vehicle.specTiles, id: \.0) { spec in
                    SpecCard(label: spec.0, value: spec.1)
                }
            }
            if !vehicle.extraSpecTiles.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(vehicle.extraSpecTiles, id: \.0) { spec in
                        SpecCard(label: spec.0, value: spec.1)
                    }
                }
            }
        }
    }

    private func extras(for vehicle: Vehicle) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: vehicles.toggleAddon) {
                HStack(spacing: 8) {
                    Image(systemName: vehicles.addonEnabled ? "checkmark.square.fill" : "square")
                        .foregroundStyle(vehicles.addonEnabled ? palette.yellow : palette.muted)
                    Text("Include \(vehicle.addonLabel)")
                        .font(.system(size: 13))
                        .foregroundStyle(palette.muted)
                }
            }
            .buttonStyle(.plain)

            DayStepper(
                days: vehicles.days,
                onDecrement: {
                    vehicles.decrementDays()
                    bookings.setEndDateFromDays(vehicles.days)
                },
                onIncrement: {
                    vehicles.incrementDays()
                    bookings.setEndDateFromDays(vehicles.days)
                }
            )
        }
    }

    private func moreLikeThis(for vehicle: Vehicle) -> some View {
        let similar = vehicles.similarVehicles(to: vehicle)
        return Group {
            if !similar.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("More like this")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(palette.text)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(similar) { item in
                                VehicleCardView(vehicle: item, compact: true) {
                                    vehicles.select(item)
                                }
                                .frame(width: 300)
                            }
                        }
                    }
                }
            }
        }
    }

    private func bottomBar(for vehicle: Vehicle) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(AppFormat.peso(vehicles.liveDailyPrice * vehicles.days))
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(palette.text)
                    Text("/ \(vehicles.days)d")
                        .font(.system(size: 12))
                        .foregroundStyle(palette.muted)
                }
                Text("\(AppFormat.peso(vehicles.liveDailyPrice)) / day")
                    .font(.system(size: 11))
                    .foregroundStyle(palette.muted)
            }
            SlideToConfirm(label: "Slide to Book") {
                bookings.prepareDraft(days: vehicles.days, contact: auth.user.phone)
                path.append(AppRoute.booking)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 16)
        .background(palette.canvas)
        .overlay(alignment: .top) {
            Rectangle().fill(palette.border).frame(height: 1)
        }
    }

    private func reviews(for vehicle: Vehicle) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reviews")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(palette.text)
            if vehicles.isLoadingReviews && vehicle.reviews.isEmpty {
                LoadingStateView(message: "Loading reviews…", compact: true)
            } else if vehicle.reviews.isEmpty {
                Text("No written reviews yet.")
                    .font(.system(size: 13))
                    .foregroundStyle(palette.muted)
            } else {
                ForEach(Array(vehicle.reviews.prefix(5))) { review in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(review.renterName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(palette.text)
                            Spacer()
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                Text("\(review.rating)")
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(palette.yellow)
                        }
                        if !review.comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(review.comment)
                                .font(.system(size: 13))
                                .foregroundStyle(palette.muted)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(palette.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(palette.border, lineWidth: 1)
                    )
                }
            }
        }
    }
}
