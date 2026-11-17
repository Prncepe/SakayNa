import SwiftUI

struct VerifiedOwnerBadge: View {
    @Environment(\.palette) private var palette
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.seal.fill")
            Text("Verified Owner")
        }
        .font(.system(size: compact ? 10 : 11, weight: .bold))
        .foregroundStyle(palette.yellow)
    }
}
