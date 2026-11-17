import SwiftUI

// Shown in place of a list while its first Firestore snapshot is loading.
struct LoadingStateView: View {
    @Environment(\.palette) private var palette
    var message: String = "Loading…"
    var compact: Bool = false

    var body: some View {
        VStack(spacing: compact ? 6 : 10) {
            ProgressView()
                .tint(palette.yellow)
            Text(message)
                .font(.system(size: compact ? 12 : 14, weight: .semibold))
                .foregroundStyle(palette.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, compact ? 8 : 32)
    }
}
