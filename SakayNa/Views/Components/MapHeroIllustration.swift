import SwiftUI

struct MapHeroIllustration: View {
    @Environment(\.palette) private var palette
    var compact: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: 0xF4F5F7))
                .frame(width: compact ? 168 : 210, height: compact ? 168 : 210)

            Capsule()
                .fill(Color(hex: 0xE5E7EB))
                .frame(width: compact ? 150 : 190, height: 34)
            Capsule()
                .fill(Color(hex: 0xE5E7EB))
                .frame(width: 34, height: compact ? 150 : 190)

            Capsule()
                .fill(palette.yellow.opacity(0.85))
                .frame(width: compact ? 88 : 110, height: 4)
                .rotationEffect(.degrees(-28))
                .offset(x: -10, y: 8)

            building(width: 34, height: 46, x: -56, y: -30)
            building(width: 26, height: 62, x: 50, y: -38)
            building(width: 30, height: 38, x: -42, y: 42)
            building(width: 22, height: 34, x: 46, y: 36)
            building(width: 18, height: 26, x: 8, y: -52)

            VStack(spacing: -2) {
                ZStack {
                    Circle()
                        .fill(palette.pin)
                        .frame(width: 38, height: 38)
                        .shadow(color: palette.pin.opacity(0.35), radius: 8, y: 4)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 14, height: 14)
                }
                PinTail()
                    .fill(palette.pin)
                    .frame(width: 16, height: 12)
            }
            .offset(y: -6)
        }
        .frame(height: compact ? 176 : 220)
        .accessibilityHidden(true)
    }

    private func building(width: CGFloat, height: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Color.white)
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color(hex: 0xE5E7EB), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 6, y: 3)
            .offset(x: x, y: y)
    }
}

private struct PinTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
