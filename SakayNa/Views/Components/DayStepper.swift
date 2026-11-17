import SwiftUI

struct DayStepper: View {
    @Environment(\.palette) private var palette
    let days: Int
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        HStack {
            Text("Rental days")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(palette.text)
            Spacer()
            HStack(spacing: 14) {
                stepperButton(systemName: "minus", action: onDecrement)
                Text("\(days)")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(palette.text)
                    .frame(minWidth: 28)
                stepperButton(systemName: "plus", action: onIncrement)
            }
        }
        .padding(16)
        .background(palette.card)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(palette.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func stepperButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(palette.onYellow)
                .frame(width: 32, height: 32)
                .background(palette.yellow)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
