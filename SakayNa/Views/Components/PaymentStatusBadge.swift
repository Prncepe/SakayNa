import SwiftUI

struct PaymentStatusBadge: View {
    @Environment(\.palette) private var palette
    let status: PaymentStatus

    var body: some View {
        Text(status.rawValue)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(background)
            .clipShape(Capsule())
    }

    private var foreground: Color {
        switch status {
        case .paid: return palette.yellow
        case .proofSubmitted: return palette.text
        case .rejected: return palette.danger
        case .unpaid: return palette.muted
        }
    }

    private var background: Color {
        switch status {
        case .paid: return palette.yellow.opacity(0.15)
        case .proofSubmitted: return palette.card
        case .rejected: return palette.danger.opacity(0.12)
        case .unpaid: return palette.fieldFill
        }
    }
}
