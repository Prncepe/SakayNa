import SwiftUI

struct SocialAuthRow: View {
    @Environment(\.palette) private var palette
    var onGoogle: () -> Void
    var onApple: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            socialButton(title: "Google", leading: { GoogleIcon() }, action: onGoogle)
            socialButton(title: "Apple", leading: {
                Image(systemName: "apple.logo")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(palette.text)
            }, action: onApple)
        }
    }

    private func socialButton<Leading: View>(
        title: String,
        @ViewBuilder leading: () -> Leading,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                leading()
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(palette.text)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(palette.card)
            .overlay(Capsule().stroke(palette.border, lineWidth: 1))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Continue with \(title)")
    }
}
