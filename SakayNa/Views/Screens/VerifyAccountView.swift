import SwiftUI
import PhotosUI
import UIKit

struct VerifyAccountView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var auth: AuthController
    @Binding var path: NavigationPath
    @State private var pickedItem: PhotosPickerItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            AppHeader(title: "Verify my account", showsBack: true, showsProfileActions: false) {
                if !path.isEmpty { path.removeLast() }
            }
            Text("Upload a government ID. For this school project, uploading it marks you as a verified owner.")
                .font(.system(size: 13))
                .foregroundStyle(palette.muted)

            PhotosPicker(selection: $pickedItem, matching: .images) {
                VStack(spacing: 8) {
                    if let fileName = auth.user.idFileName {
                        StoredImage(fileName: fileName, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        Text(auth.user.isVerifiedOwner ? "Verified ✓  Tap to replace" : "ID uploaded — tap to replace")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(palette.yellow)
                    } else {
                        Image(systemName: "person.text.rectangle")
                        Text("Tap to upload a government ID")
                            .font(.system(size: 13, weight: .semibold))
                    }
                }
                .foregroundStyle(auth.user.idFileName == nil ? palette.muted : palette.yellow)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 128)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            auth.user.idFileName == nil ? palette.border : palette.yellow,
                            style: StrokeStyle(lineWidth: 1.5, dash: [6])
                        )
                )
            }
            .buttonStyle(.plain)
            .onChange(of: pickedItem) { _, item in
                Task { await loadID(item) }
            }

            if auth.user.isVerifiedOwner {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                    Text("Your profile shows Verified Owner.")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(palette.yellow)
            }

            Spacer()
        }
        .padding(24)
        .background(palette.canvas.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private func loadID(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        await MainActor.run {
            auth.saveGovernmentID(image)
        }
    }
}
