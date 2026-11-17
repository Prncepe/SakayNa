import SwiftUI
import PhotosUI
import UIKit

struct ConditionPhotoSheet: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var bookings: BookingController
    @State private var pickedItems: [ConditionSide: PhotosPickerItem] = [:]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Add Front, Back, Left, and Right photos. Fuel is a picker. Note is optional.")
                        .font(.system(size: 13))
                        .foregroundStyle(palette.muted)

                    ForEach(ConditionSide.allCases, id: \.self) { side in
                        photoRow(side)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("FUEL LEVEL")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.3)
                            .foregroundStyle(palette.muted)
                        Picker("Fuel", selection: $bookings.conditionFuel) {
                            ForEach(FuelLevel.allCases, id: \.self) { level in
                                Text(level.rawValue).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTE (OPTIONAL)")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.3)
                            .foregroundStyle(palette.muted)
                        TextField("Anything to add?", text: $bookings.conditionNote, axis: .vertical)
                            .lineLimit(2...4)
                            .padding(16)
                            .foregroundStyle(palette.text)
                            .background(palette.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(palette.border, lineWidth: 1)
                            )
                    }

                    PrimaryButton(
                        title: bookings.conditionAction == .pickup ? "Confirm Pickup" : "Confirm Return",
                        isEnabled: bookings.canConfirmCondition,
                        action: bookings.confirmCondition
                    )
                }
                .padding(24)
            }
            .background(palette.canvas)
            .navigationTitle(bookings.conditionAction == .pickup ? "Pickup checklist" : "Return checklist")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { bookings.showConditionSheet = false }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func photoRow(_ side: ConditionSide) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(side.rawValue.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(1.3)
                .foregroundStyle(palette.muted)

            PhotosPicker(selection: binding(for: side), matching: .images) {
                HStack(spacing: 12) {
                    if let name = bookings.conditionPhotos[side.rawValue] {
                        StoredImage(fileName: name, contentMode: .fill)
                            .frame(width: 72, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        Text("Retake \(side.rawValue.lowercased()) photo")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(palette.text)
                    } else {
                        Image(systemName: "camera")
                            .foregroundStyle(palette.muted)
                            .frame(width: 72, height: 56)
                            .background(palette.fieldFill)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        Text("Add \(side.rawValue.lowercased()) photo")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(palette.text)
                    }
                    Spacer()
                }
                .padding(12)
                .background(palette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(palette.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .onChange(of: pickedItems[side]) { _, item in
                Task { await loadPhoto(item, side: side) }
            }
        }
    }

    private func binding(for side: ConditionSide) -> Binding<PhotosPickerItem?> {
        Binding(
            get: { pickedItems[side] },
            set: { pickedItems[side] = $0 }
        )
    }

    private func loadPhoto(_ item: PhotosPickerItem?, side: ConditionSide) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        await MainActor.run {
            bookings.saveConditionPhoto(side: side, image: image)
        }
    }
}
