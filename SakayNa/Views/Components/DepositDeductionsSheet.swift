import SwiftUI
import PhotosUI
import UIKit

struct DepositDeductionsSheet: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var bookings: BookingController
    @State private var pickedPhoto: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                if let booking = currentBooking {
                    Text("Deposit \(AppFormat.peso(booking.deposit)). Refund so far \(AppFormat.peso(booking.depositRefund)).")
                        .font(.system(size: 13))
                        .foregroundStyle(palette.muted)

                    if !booking.depositDeductions.isEmpty {
                        ForEach(booking.depositDeductions) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.reason)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(palette.text)
                                    Text(AppFormat.peso(item.amount))
                                        .font(.system(size: 13))
                                        .foregroundStyle(palette.muted)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(palette.card)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }

                    PillField(
                        label: "AMOUNT",
                        placeholder: "0",
                        keyboard: .numberPad,
                        text: $bookings.draftDeductionAmount
                    )
                    PillField(
                        label: "REASON",
                        placeholder: "e.g. Scratched bumper",
                        text: $bookings.draftDeductionReason
                    )

                    PhotosPicker(selection: $pickedPhoto, matching: .images) {
                        Text(bookings.draftDeductionPhoto == nil ? "Optional photo" : "Photo added — tap to replace")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(palette.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(palette.card)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .onChange(of: pickedPhoto) { _, item in
                        Task { await loadPhoto(item) }
                    }

                    OutlineButton(title: "Add deduction", action: bookings.addDeduction)
                }

                Spacer()

                PrimaryButton(title: "Done", action: bookings.finishDeductions)
            }
            .padding(24)
            .background(palette.canvas)
            .navigationTitle("Deposit deductions")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { bookings.finishDeductions() }
                }
            }
        }
        .presentationDetents([.large])
    }

    private var currentBooking: Booking? {
        guard let id = bookings.deductionBookingId else { return nil }
        return bookings.booking(id: id)
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        await MainActor.run {
            bookings.saveDeductionPhoto(image)
        }
    }
}
