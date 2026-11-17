import SwiftUI

struct ReceiptView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var bookings: BookingController
    @EnvironmentObject private var auth: AuthController
    @Binding var path: NavigationPath
    let bookingId: String
    @State private var pdfURL: URL?

    var body: some View {
        Group {
            if let booking = bookings.booking(id: bookingId) {
                receipt(booking)
            } else if bookings.isLoading {
                LoadingStateView(message: "Loading receipt…")
            } else {
                Text("Receipt not found")
                    .foregroundStyle(palette.muted)
            }
        }
        .background(palette.canvas.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private func receipt(_ booking: Booking) -> some View {
        let renterName = auth.displayName(id: booking.renterId, fallback: booking.renterName)
        let ownerName = auth.displayName(id: booking.vehicle.ownerId)
        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AppHeader(title: "Receipt", showsBack: true, showsProfileActions: false) {
                    if !path.isEmpty { path.removeLast() }
                }

                AppCard {
                    ReceiptDocumentView(
                        booking: booking,
                        renterName: renterName,
                        ownerName: ownerName
                    )
                }

                if let pdfURL {
                    ShareLink(item: pdfURL) {
                        Text("Share PDF")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(palette.onYellow)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(palette.yellow)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(24)
        }
        .onAppear {
            pdfURL = ReceiptPDFBuilder.makeFile(
                booking: booking,
                renterName: renterName,
                ownerName: ownerName
            )
        }
    }
}
