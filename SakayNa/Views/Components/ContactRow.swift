import SwiftUI
import UIKit

struct ContactRow: View {
    @Environment(\.palette) private var palette
    let title: String
    let number: String
    var onMessage: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(palette.muted)
            Text(number)
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(palette.text)
            HStack(spacing: 8) {
                actionChip(title: "Call", systemName: "phone.fill") {
                    if let url = URL(string: "tel://\(number.filter { $0.isNumber })") {
                        UIApplication.shared.open(url)
                    }
                }
                actionChip(title: "Copy", systemName: "doc.on.doc") {
                    UIPasteboard.general.string = number
                }
                if let onMessage {
                    actionChip(title: "Message", systemName: "message.fill", action: onMessage)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func actionChip(title: String, systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemName)
                Text(title)
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(palette.onYellow)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(palette.yellow)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
