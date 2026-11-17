import SwiftUI

struct ScanToPayCard: View {
    @Environment(\.palette) private var palette
    let method: PaymentMethod
    let ownerName: String
    let accountNumber: String
    var qrAvailable: Bool = false
    var qrFileName: String? = nil

    var body: some View {
        AppCard {
            VStack(spacing: 12) {
                Text("Scan to Pay")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(palette.text)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    if let qrFileName, PhotoService.isReference(qrFileName) {
                        StoredImage(fileName: qrFileName, contentMode: .fit)
                            .frame(width: 140, height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    } else if qrAvailable {
                        mockQR
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "qrcode")
                                .font(.system(size: 40))
                                .foregroundStyle(palette.muted)
                            Text("QR code not yet provided — use the number below")
                                .font(.system(size: 13))
                                .foregroundStyle(palette.muted)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 160, height: 160)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(palette.border, style: StrokeStyle(lineWidth: 2, dash: [6]))
                        )
                    }
                }

                Text("Send payment to \(ownerName) via \(method.rawValue)")
                    .font(.system(size: 13))
                    .foregroundStyle(palette.muted)
                    .multilineTextAlignment(.center)

                Text(accountNumber)
                    .font(.system(size: 16, weight: .heavy))
                    .tracking(0.8)
                    .foregroundStyle(palette.text)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(palette.fieldFill)
                    .overlay(Capsule().stroke(palette.border, lineWidth: 1))
            }
        }
    }

    private var mockQR: some View {
        VStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { row in
                HStack(spacing: 3) {
                    ForEach(0..<5, id: \.self) { col in
                        Rectangle()
                            .fill(shouldFill(row: row, col: col) ? Color(hex: 0x111111) : Color.clear)
                    }
                }
            }
        }
        .padding(12)
        .frame(width: 140, height: 140)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: Color(hex: 0xF8D33F).opacity(0.15), radius: 6)
    }

    private func shouldFill(row: Int, col: Int) -> Bool {
        (row + col).isMultiple(of: 2) || (row == 0 && col < 3) || (row == 4 && col > 1)
    }
}
