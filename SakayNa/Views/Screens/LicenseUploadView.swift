import SwiftUI
import PhotosUI
import UIKit

struct LicenseUploadView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var auth: AuthController
    @Binding var path: NavigationPath
    @State private var pickedItem: PhotosPickerItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            AppHeader(title: "ID / License", showsBack: true, showsProfileActions: false) {
                if !path.isEmpty { path.removeLast() }
            }
            Text("Upload a valid driver's license matching your account name.")
                .font(.system(size: 13))
                .foregroundStyle(palette.muted)

            PhotosPicker(selection: $pickedItem, matching: .images) {
                VStack(spacing: 8) {
                    if let fileName = auth.user.licenseFileName {
                        StoredImage(fileName: fileName, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        Text("License uploaded ✓  Tap to replace")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(palette.yellow)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                        Text("Tap to upload Driver's License")
                            .font(.system(size: 13, weight: .semibold))
                    }
                }
                .foregroundStyle(auth.hasLicense ? palette.yellow : palette.muted)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 128)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            auth.hasLicense ? palette.yellow : palette.border,
                            style: StrokeStyle(lineWidth: 1.5, dash: [6])
                        )
                )
            }
            .buttonStyle(.plain)
            .onChange(of: pickedItem) { _, item in
                Task { await loadLicense(item) }
            }
            Spacer()
        }
        .padding(24)
        .background(palette.canvas.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private func loadLicense(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        await MainActor.run {
            auth.saveLicenseImage(image)
        }
    }
}
