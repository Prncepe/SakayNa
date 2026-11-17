import SwiftUI

struct LoadingOverlay: View {
    @Environment(\.palette) private var palette
    var message: String = "Please wait…"

    var body: some View {
        ZStack {
            palette.canvas.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                    .tint(palette.yellow)
                    .scaleEffect(1.3)
                Text(message)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(palette.text)
            }
            .padding(24)
            .background(palette.card)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }
}
