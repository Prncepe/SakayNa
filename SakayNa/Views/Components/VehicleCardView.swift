import SwiftUI

struct VehicleCardView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var vehicles: VehicleController
    @EnvironmentObject private var auth: AuthController
    let vehicle: Vehicle
    var compact: Bool = false
    var showsFavorite: Bool = true
    var availabilityLabel: String? = nil
    let action: () -> Void

    private var imageHeight: CGFloat { compact ? 78 : 110 }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: action) {
                ZStack(alignment: .bottomTrailing) {
                    VStack(alignment: .leading, spacing: compact ? 6 : 8) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(vehicle.name)
                                    .font(.system(size: compact ? 16 : 20, weight: .bold))
                                    .foregroundStyle(palette.text)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                if auth.user(id: vehicle.ownerId)?.isVerifiedOwner == true {
                                    VerifiedOwnerBadge(compact: compact)
                                }
                                HStack(spacing: 6) {
                                    Image(systemName: "person.2")
                                    Text(vehicle.riderLabel)
                                }
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(palette.muted)
                                HStack(spacing: 6) {
                                    Image(systemName: "mappin.and.ellipse")
                                    Text(vehicle.location)
                                        .lineLimit(1)
                                }
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(palette.muted)
                            }
                            Spacer(minLength: compact ? 72 : 96)
                        }

                        Spacer(minLength: compact ? 36 : 48)

                        VStack(alignment: .leading, spacing: 8) {
                            pricePill
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(palette.yellow)
                                Text(vehicle.rating)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(palette.text)
                                Text("(\(vehicle.reviewCount))")
                                    .foregroundStyle(palette.muted)
                            }
                            .font(.system(size: 12))
                            if let availabilityLabel {
                                Text(availabilityLabel)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(palette.yellow)
                            }
                        }
                    }
                    .padding(compact ? 14 : 18)
                    .padding(.trailing, compact ? 8 : 12)

                    VStack(spacing: 0) {
                        VehicleImageView(vehicle: vehicle, height: imageHeight)
                            .shadow(color: palette.shadow, radius: 8, y: 4)
                    }
                    .frame(width: compact ? 130 : 170)
                    .overlay(alignment: .bottom) {
                        Ellipse()
                            .fill(palette.text.opacity(0.12))
                            .frame(width: compact ? 90 : 120, height: 14)
                            .offset(y: 2)
                    }
                    .padding(.trailing, 8)
                    .padding(.bottom, 10)
                }
                .frame(minHeight: compact ? 150 : 188)
                .background(palette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(palette.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                if showsFavorite {
                    Button {
                        vehicles.toggleFavorite(id: vehicle.id)
                    } label: {
                        Image(systemName: vehicles.favoriteIds.contains(vehicle.id) ? "heart.fill" : "heart")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(vehicles.favoriteIds.contains(vehicle.id) ? palette.yellow : palette.text)
                            .frame(width: 32, height: 32)
                            .background(palette.canvas.opacity(0.92))
                            .overlay(Circle().stroke(palette.border, lineWidth: 1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(palette.text)
                    .frame(width: 32, height: 32)
                    .background(palette.canvas.opacity(0.92))
                    .overlay(Circle().stroke(palette.border, lineWidth: 1))
                    .clipShape(Circle())
                    .allowsHitTesting(false)
            }
            .padding(14)
        }
    }

    private var pricePill: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("Price")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(palette.muted)
            Text("\(AppFormat.peso(vehicle.pricePerDay))/day")
                .font(.system(size: compact ? 13 : 15, weight: .bold))
                .foregroundStyle(palette.text)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(palette.fieldFill)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(palette.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
