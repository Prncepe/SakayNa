import SwiftUI
import PhotosUI
import UIKit

struct PaymentMethodsView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var auth: AuthController
    @Binding var path: NavigationPath
    @State private var pickedQR: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AppHeader(
                    title: auth.user.role == .owner ? "Payout Methods" : "Payment Methods",
                    showsBack: true,
                    showsProfileActions: false
                ) {
                    path.removeLast()
                }

                Form {
                    Section("Wallets") {
                        TextField("GCash number", text: $auth.gcashDraft)
                            .keyboardType(.phonePad)
                        TextField("Maya number", text: $auth.mayaDraft)
                            .keyboardType(.phonePad)
                        TextField("Bank account", text: $auth.bankDraft)
                    }
                    Section("QRPh") {
                        Toggle("Enable QRPh", isOn: $auth.qrPhDraft)
                            .tint(palette.yellow)
                    }
                }
                .frame(minHeight: 340)
                .scrollContentBackground(.hidden)

                PhotosPicker(selection: $pickedQR, matching: .images) {
                    VStack(spacing: 8) {
                        if let fileName = auth.user.qrFileName {
                            StoredImage(fileName: fileName, contentMode: .fit)
                                .frame(height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            Text("QR code uploaded ✓  Tap to replace")
                                .font(.system(size: 13, weight: .semibold))
                        } else {
                            Image(systemName: "qrcode")
                            Text("Tap to upload your GCash/Maya QR code")
                                .font(.system(size: 13, weight: .semibold))
                        }
                    }
                    .foregroundStyle(auth.hasQR ? palette.yellow : palette.muted)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 72)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                auth.hasQR ? palette.yellow : palette.border,
                                style: StrokeStyle(lineWidth: 1.5, dash: [6])
                            )
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .onChange(of: pickedQR) { _, item in
                    Task { await loadQR(item) }
                }

                PrimaryButton(title: "Save Methods") {
                    auth.savePaymentMethods()
                    path.removeLast()
                }
                .padding(.horizontal, 24)
            }
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .background(palette.canvas.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private func loadQR(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        await MainActor.run {
            auth.saveQRImage(image)
        }
    }
}
