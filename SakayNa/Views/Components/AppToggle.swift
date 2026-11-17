import SwiftUI

struct AppToggle: View {
    @Environment(\.palette) private var palette
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Capsule()
                .fill(isOn ? palette.yellow : palette.text.opacity(0.15))
                .frame(width: 44, height: 26)
                .overlay(alignment: isOn ? .trailing : .leading) {
                    Circle()
                        .fill(isOn ? palette.onYellow : Color.white.opacity(0.5))
                        .frame(width: 20, height: 20)
                        .padding(3)
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
    }
}
