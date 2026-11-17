import SwiftUI

struct BookingConfirmationView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var vehicles: VehicleController
    @EnvironmentObject private var bookings: BookingController

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(palette.onYellow)
                .frame(width: 96, height: 96)
                .background(palette.yellow)
                .clipShape(Circle())

            Text("Request submitted")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(palette.text)

            if let vehicle = vehicles.selectedVehicle {
                Text("Your \(vehicle.name) booking is pending owner approval.")
                    .font(.system(size: 13))
                    .foregroundStyle(palette.muted)
                    .multilineTextAlignment(.center)

                AppCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(AppFormat.shortDate(bookings.startDate)) — \(AppFormat.shortDate(bookings.endDate))")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(palette.text)
                        Text("\(bookings.location) pickup")
                            .font(.system(size: 13))
                            .foregroundStyle(palette.muted)
                        StatusPill(status: .pending)
                        Text(AppFormat.peso(bookings.lastConfirmedTotal))
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundStyle(palette.text)
                    }
                }
            }

            PrimaryButton(title: "View My Bookings") {
                bookings.goToBookingsTab()
            }
            OutlineButton(title: "Back to Home") {
                bookings.goToHomeTab()
            }
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.canvas.ignoresSafeArea())
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}
