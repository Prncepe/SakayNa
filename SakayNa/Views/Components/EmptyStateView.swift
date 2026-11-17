import SwiftUI

struct EmptyStateView: View {
    @Environment(\.palette) private var palette
    let systemImage: String
    let title: String
    var message: String = ""
    var compact: Bool = false

    var body: some View {
        VStack(spacing: compact ? 8 : 12) {
            Image(systemName: systemImage)
                .font(.system(size: compact ? 22 : 36))
                .foregroundStyle(palette.muted.opacity(0.5))
            Text(title)
                .font(.system(size: compact ? 14 : 16, weight: .semibold))
                .foregroundStyle(palette.text)
                .multilineTextAlignment(.center)
            if !message.isEmpty {
                Text(message)
                    .font(.system(size: compact ? 12 : 13))
                    .foregroundStyle(palette.muted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, compact ? 8 : 32)
        .padding(.horizontal, 8)
    }
}
