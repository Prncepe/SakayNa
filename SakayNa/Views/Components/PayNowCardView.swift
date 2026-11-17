import SwiftUI
import PhotosUI
import UIKit

struct PayNowCardView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var bookings: BookingController
    let booking: Booking
    @State private var pickedProof: PhotosPickerItem?

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Pay now")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(palette.text)
                    Spacer()
                    PaymentStatusBadge(status: booking.currentPaymentStatus)
                }

                if let owner = auth.user(id: booking.vehicle.ownerId) {
                    Text(payoutText(for: owner))
                        .font(.system(size: 13))
                        .foregroundStyle(palette.muted)
                    if let qr = owner.qrFileName {
                        StoredImage(fileName: qr, contentMode: .fit)
                            .frame(height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }

                Text("Amount due \(AppFormat.peso(booking.totalPrice))")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(palette.text)

                if booking.currentPaymentStatus == .rejected, let reason = booking.paymentRejectReason {
                    Text("Rejected: \(reason). Upload a new proof.")
                        .font(.system(size: 13))
                        .foregroundStyle(palette.danger)
                }

                PillField(
                    label: "REFERENCE NUMBER",
                    placeholder: "At least 6 characters",
                    text: $bookings.paymentReferenceDraft,
                    error: bookings.paymentProofError
                )

                PhotosPicker(selection: $pickedProof, matching: .images) {
                    Text(bookings.paymentProofDraft == nil ? "Upload payment screenshot" : "Screenshot added — tap to replace")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(palette.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(palette.fieldFill)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .onChange(of: pickedProof) { _, item in
                    Task { await loadProof(item) }
                }

                PrimaryButton(title: "Submit proof") {
                    bookings.submitPaymentProof(bookingId: booking.id)
                }
            }
        }
        .onAppear {
            bookings.preparePaymentProof(bookingId: booking.id)
        }
    }

    private func payoutText(for owner: User) -> String {
        switch booking.paymentMethod {
        case .gcash:
            return "GCash: \(owner.gcashNumber.isEmpty ? "Not added" : owner.gcashNumber)"
        case .maya:
            return "Maya: \(owner.mayaNumber.isEmpty ? "Not added" : owner.mayaNumber)"
        case .bankTransfer:
            return "Bank: \(owner.bankAccount.isEmpty ? "Not added" : owner.bankAccount)"
        case .qrPh:
            return owner.qrPhEnabled ? "Scan the owner's QR Ph code." : "QR Ph is not enabled yet."
        case .cash:
            return "Pay in cash at pickup."
        }
    }

    private func loadProof(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        await MainActor.run {
            bookings.savePaymentProofPhoto(image)
        }
    }
}
