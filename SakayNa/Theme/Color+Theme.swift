import SwiftUI

enum AppTheme: String, Codable {
    case dark
    case light
}

struct ThemePalette {
    let canvas: Color
    let card: Color
    let border: Color
    let text: Color
    let muted: Color
    let yellow: Color
    let onYellow: Color
    let placeholder: Color
    let fieldFill: Color
    let glow: Color
    let slideTrack: Color
    let loginGlow: Color
    let shadow: Color
    let pin: Color
    var danger: Color { pin }

    static func make(_ theme: AppTheme) -> ThemePalette {
        switch theme {
        case .dark:
            return ThemePalette(
                canvas: Color(hex: 0x0B0B0D),
                card: Color.white.opacity(0.07),
                border: Color.white.opacity(0.10),
                text: Color.white.opacity(0.92),
                muted: Color.white.opacity(0.55),
                yellow: Color(hex: 0xF5C518),
                onYellow: Color(hex: 0x111111),
                placeholder: Color.white.opacity(0.35),
                fieldFill: Color.white.opacity(0.06),
                glow: Color.clear,
                slideTrack: Color.white.opacity(0.10),
                loginGlow: Color.clear,
                shadow: Color.black.opacity(0.45),
                pin: Color(hex: 0xEF4444)
            )
        case .light:
            return ThemePalette(
                canvas: Color(hex: 0xFFFFFF),
                card: Color(hex: 0xFFFFFF),
                border: Color(hex: 0xE6E7EB),
                text: Color(hex: 0x111111),
                muted: Color(hex: 0x6B7280),
                yellow: Color(hex: 0xF5C518),
                onYellow: Color(hex: 0x111111),
                placeholder: Color(hex: 0x9CA3AF),
                fieldFill: Color(hex: 0xFFFFFF),
                glow: Color.clear,
                slideTrack: Color(hex: 0xF3F4F6),
                loginGlow: Color.clear,
                shadow: Color.black.opacity(0.08),
                pin: Color(hex: 0xEF4444)
            )
        }
    }
}

extension View {
    func sakayCardChrome(_ palette: ThemePalette, radius: CGFloat = 24) -> some View {
        self
            .background(palette.card)
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(palette.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: palette.shadow, radius: 18, y: 8)
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    init(hexString: String) {
        var hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if hex.count == 3 {
            hex = hex.map { "\($0)\($0)" }.joined()
        }
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        self.init(hex: UInt(value))
    }
}

private struct PaletteKey: EnvironmentKey {
    static let defaultValue = ThemePalette.make(.light)
}

extension EnvironmentValues {
    var palette: ThemePalette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}
