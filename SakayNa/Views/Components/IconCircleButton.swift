import SwiftUI

struct IconCircleButton: View {
    @Environment(\.palette) private var palette
    let systemName: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(palette.text)
                .frame(width: 40, height: 40)
                .background(palette.card)
                .overlay(Circle().stroke(palette.border, lineWidth: 1))
                .clipShape(Circle())
                .shadow(color: palette.shadow, radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }
}
