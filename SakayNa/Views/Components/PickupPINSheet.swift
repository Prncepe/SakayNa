import SwiftUI

struct PickupPINSheet: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var bookings: BookingController

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Ask the renter for the 4-digit pickup PIN, then enter it to open the checklist.")
                    .font(.system(size: 13))
                    .foregroundStyle(palette.muted)

                PillField(
                    label: "PICKUP PIN",
                    placeholder: "0000",
                    keyboard: .numberPad,
                    text: $bookings.pickupPINDraft,
                    error: bookings.pickupPINError
                )

                Spacer()

                PrimaryButton(title: "Confirm PIN", action: bookings.verifyPickupPIN)
            }
            .padding(24)
            .background(palette.canvas)
            .navigationTitle("Pickup PIN")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { bookings.showPickupPINSheet = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
