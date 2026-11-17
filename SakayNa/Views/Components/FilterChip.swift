import SwiftUI

struct FilterChip: View {
    @Environment(\.palette) private var palette
    let title: String
    let isActive: Bool
    var fillsWidth: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isActive ? palette.onYellow : palette.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: fillsWidth ? .infinity : nil)
                .background(isActive ? palette.yellow : palette.card)
                .overlay(
                    Capsule()
                        .stroke(isActive ? palette.yellow : palette.border, lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
