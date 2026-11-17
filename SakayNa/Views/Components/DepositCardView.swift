import SwiftUI

struct DepositCardView: View {
    @Environment(\.palette) private var palette
    let booking: Booking
    var onMessageOwner: () -> Void
    var onSelectPhoto: (String) -> Void

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Deposit")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(palette.text)
                row("Security deposit", AppFormat.peso(booking.deposit))
                ForEach(booking.depositDeductions) { item in
                    HStack(alignment: .top, spacing: 10) {
                        if let photo = item.photoFile {
                            Button {
                                onSelectPhoto(photo)
                            } label: {
                                StoredImage(fileName: photo, contentMode: .fill)
                                    .frame(width: 48, height: 40)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.reason)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(palette.text)
                            Text("Deduction")
                                .font(.system(size: 11))
                                .foregroundStyle(palette.muted)
                        }
                        Spacer()
                        Text(AppFormat.peso(item.amount))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(palette.danger)
                    }
                }
                Divider().overlay(palette.border)
                row("Refund", AppFormat.peso(booking.depositRefund))
                OutlineButton(title: "Message owner about this", action: onMessageOwner)
            }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(palette.muted)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(palette.text)
        }
    }
}
