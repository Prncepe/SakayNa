import SwiftUI

struct RateTripView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var bookings: BookingController
    @EnvironmentObject private var vehicles: VehicleController
    @Binding var path: NavigationPath
    let bookingId: String

    @State private var firstScore = 0
    @State private var secondScore = 0
    @State private var comment = ""

    var body: some View {
        Group {
            if let booking = bookings.booking(id: bookingId) {
                form(booking)
            } else if bookings.isLoading {
                LoadingStateView(message: "Loading booking…")
            } else {
                Text("Booking not found")
                    .foregroundStyle(palette.muted)
            }
        }
        .background(palette.canvas.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private func form(_ booking: Booking) -> some View {
        let isOwner = auth.user.role == .owner
        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AppHeader(
                    title: isOwner ? "Rate Renter" : "Rate your trip",
                    showsBack: true,
                    showsProfileActions: false
                ) {
                    if !path.isEmpty { path.removeLast() }
                }

                Text(booking.vehicle.name)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(palette.text)

                if isOwner {
                    stars(title: "Renter rating", score: $firstScore)
                } else {
                    stars(title: "Vehicle rating", score: $firstScore)
                    stars(title: "Owner rating", score: $secondScore)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("COMMENT (OPTIONAL)")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.3)
                        .foregroundStyle(palette.muted)
                    TextField("How was the trip?", text: $comment, axis: .vertical)
                        .lineLimit(3...6)
                        .padding(16)
                        .foregroundStyle(palette.text)
                        .background(palette.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(palette.border, lineWidth: 1)
                        )
                }

                PrimaryButton(
                    title: "Submit Rating",
                    isEnabled: isOwner ? firstScore > 0 : firstScore > 0 && secondScore > 0
                ) {
                    if isOwner {
                        bookings.saveOwnerRating(bookingId: booking.id, renterRating: firstScore, comment: comment)
                    } else {
                        let isFirstReview = !booking.renterHasRated
                        bookings.saveRenterRatings(
                            bookingId: booking.id,
                            vehicleRating: firstScore,
                            ownerRating: secondScore,
                            comment: comment
                        )
                        if isFirstReview {
                            vehicles.addReview(
                                bookingId: booking.id,
                                vehicleId: booking.vehicle.id,
                                rating: firstScore,
                                comment: comment,
                                renterId: auth.user.id,
                                renterName: auth.user.name
                            )
                        }
                    }
                    if !path.isEmpty { path.removeLast() }
                }
            }
            .padding(24)
        }
        .onAppear {
            firstScore = isOwner ? (booking.renterRating ?? 0) : (booking.vehicleRating ?? 0)
            secondScore = booking.ownerRating ?? 0
            comment = booking.ratingComment ?? ""
        }
    }

    private func stars(title: String, score: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(palette.text)
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        score.wrappedValue = star
                    } label: {
                        Image(systemName: score.wrappedValue >= star ? "star.fill" : "star")
                            .font(.system(size: 28))
                            .foregroundStyle(palette.yellow)
                    }
                    .buttonStyle(.plain)
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
    }
}
