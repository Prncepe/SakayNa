import SwiftUI

struct ConditionPhotosView: View {
    @Environment(\.palette) private var palette
    let booking: Booking
    var onSelect: (String) -> Void

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Condition photos")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(palette.text)

                ForEach(ConditionSide.allCases, id: \.self) { side in
                    HStack(alignment: .top, spacing: 12) {
                        Text(side.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(palette.muted)
                            .frame(width: 48, alignment: .leading)
                        photoCell(title: "Pickup", fileName: booking.photosAtPickup[side.rawValue])
                        photoCell(title: "Return", fileName: booking.photosAtReturn[side.rawValue])
                    }
                }

                if let pickupFuel = booking.pickupFuel, !pickupFuel.isEmpty {
                    Text("Fuel at pickup: \(pickupFuel)")
                        .font(.system(size: 12))
                        .foregroundStyle(palette.muted)
                }
                if let returnFuel = booking.returnFuel, !returnFuel.isEmpty {
                    Text("Fuel at return: \(returnFuel)")
                        .font(.system(size: 12))
                        .foregroundStyle(palette.muted)
                }
                if let note = booking.pickupNote, !note.isEmpty {
                    Text("Pickup note: \(note)")
                        .font(.system(size: 12))
                        .foregroundStyle(palette.muted)
                }
                if let note = booking.returnNote, !note.isEmpty {
                    Text("Return note: \(note)")
                        .font(.system(size: 12))
                        .foregroundStyle(palette.muted)
                }
            }
        }
    }

    private func photoCell(title: String, fileName: String?) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(palette.muted)
            if let fileName {
                Button {
                    onSelect(fileName)
                } label: {
                    StoredImage(fileName: fileName, contentMode: .fill)
                        .frame(height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(palette.fieldFill)
                    .overlay(
                        Text("None")
                            .font(.system(size: 11))
                            .foregroundStyle(palette.muted)
                    )
                    .frame(height: 72)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
