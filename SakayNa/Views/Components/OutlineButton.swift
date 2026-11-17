import SwiftUI

struct OutlineButton: View {
    @Environment(\.palette) private var palette
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(palette.text)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(palette.card)
                .overlay(
                    Capsule()
                        .stroke(palette.border, lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .buttonStyle(.plain)
    }
}
