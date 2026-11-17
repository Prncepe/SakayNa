import SwiftUI

struct RenterInfoCard: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var bookings: BookingController
    let booking: Booking

    var body: some View {
        let renter = auth.user(id: booking.renterId ?? "")
        let rating = bookings.renterRatingSummary(renter: renter)
        let trips = bookings.renterCompletedTripCount(renterId: booking.renterId)
        VStack(alignment: .leading, spacing: 10) {
            Text("Renter info")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(palette.text)
            row("Name", renter?.name ?? booking.renterName)
            row("Phone", renter?.phone ?? booking.renterContact)
            row("Average rating", rating.count == 0 ? rating.text : "\(rating.text) (\(rating.count))")
            row("Completed trips", "\(trips)")
            if let license = booking.renterLicenseRef {
                OutlineButton(title: "View license") {
                    bookings.fullScreenPhoto = license
                }
            } else {
                Text("No license on file")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(palette.danger)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.fieldFill)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(palette.muted)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(palette.text)
        }
    }
}
