import SwiftUI

struct PrimaryButton: View {
    @Environment(\.palette) private var palette
    let title: String
    var systemImage: String? = nil
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(palette.onYellow)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(palette.yellow)
            .clipShape(Capsule())
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .buttonStyle(.plain)
    }
}
