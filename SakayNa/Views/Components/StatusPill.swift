import SwiftUI

struct StatusPill: View {
    let status: BookingStatus

    var body: some View {
        Text(status.badgeLabel)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(background)
            .clipShape(Capsule())
    }

    private var foreground: Color {
        switch status {
        case .pending: return Color(hex: 0xB45309)
        case .approved: return Color(hex: 0x3B82F6)
        case .ongoing: return Color(hex: 0x22C55E)
        case .declined, .cancelled: return Color(hex: 0xEF4444)
        case .completed, .upcoming: return Color.white.opacity(0.55)
        }
    }

    private var background: Color {
        switch status {
        case .pending: return Color(hex: 0xFBBF24).opacity(0.15)
        case .approved: return Color(hex: 0x3B82F6).opacity(0.15)
        case .ongoing: return Color(hex: 0x22C55E).opacity(0.15)
        case .declined, .cancelled: return Color(hex: 0xEF4444).opacity(0.12)
        case .completed, .upcoming: return Color.white.opacity(0.07)
        }
    }
}
