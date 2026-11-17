import SwiftUI
import PhotosUI
import UIKit

struct VehiclePhotoPicker: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var vehicles: VehicleController
    @State private var pickedPhotos: [PhotosPickerItem] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PHOTOS (UP TO 5)")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.3)
                .foregroundStyle(palette.muted)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(vehicles.draftPhotoFiles.enumerated()), id: \.element) { index, file in
                        ZStack(alignment: .topTrailing) {
                            StoredImage(fileName: file, contentMode: .fill)
                                .frame(width: 110, height: 88)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            Button {
                                vehicles.removeDraftPhoto(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(palette.text)
                                    .background(palette.canvas.clipShape(Circle()))
                            }
                            .buttonStyle(.plain)
                            .offset(x: 4, y: -4)
                        }
                        .overlay(alignment: .bottom) {
                            Text(index == 0 ? "Cover" : "Set cover")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(palette.onYellow)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(palette.yellow)
                                .clipShape(Capsule())
                                .padding(.bottom, 6)
                                .onTapGesture {
                                    vehicles.makeCoverPhoto(at: index)
                                }
                        }
                    }

                    if vehicles.draftPhotoFiles.count < 5 {
                        PhotosPicker(
                            selection: $pickedPhotos,
                            maxSelectionCount: 5 - vehicles.draftPhotoFiles.count,
                            matching: .images
                        ) {
                            VStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Add")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(palette.muted)
                            .frame(width: 110, height: 88)
                            .background(palette.fieldFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(palette.border, style: StrokeStyle(lineWidth: 1, dash: [6]))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .onChange(of: pickedPhotos) { _, items in
                Task { await loadPhotos(items) }
            }

            if vehicles.draftPhotoFiles.isEmpty, let selected = vehicles.selectedVehicle, !selected.imageName.isEmpty {
                Text("Current cover is the original listing photo.")
                    .font(.system(size: 12))
                    .foregroundStyle(palette.muted)
            }
        }
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) async {
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { continue }
            await MainActor.run {
                vehicles.savePickedPhoto(image)
            }
        }
        await MainActor.run {
            pickedPhotos = []
        }
    }
}
