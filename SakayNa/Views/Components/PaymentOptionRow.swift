import SwiftUI

struct PaymentOptionRow: View {
    @Environment(\.palette) private var palette
    let method: PaymentMethod
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(method.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(palette.text)
                    Text(method.detail)
                        .font(.system(size: 12))
                        .foregroundStyle(palette.muted)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(palette.yellow)
                }
            }
            .padding(16)
            .background(isSelected ? palette.yellow.opacity(0.16) : palette.card)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? palette.yellow : palette.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
