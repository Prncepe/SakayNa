import SwiftUI

struct PriceBreakdownCard: View {
    @Environment(\.palette) private var palette
    let vehicle: Vehicle
    let days: Int
    let addonPrice: Int
    var deposit: Int = 0
    var lateFee: Int = 0
    let totalPrice: Int

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Price Breakdown")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(palette.text)
                row(
                    "Base price × \(days) \(days == 1 ? "day" : "days")",
                    AppFormat.peso(vehicle.pricePerDay * days)
                )
                row("Add-ons", AppFormat.peso(addonPrice))
                row("Security deposit (refundable)", AppFormat.peso(deposit))
                if lateFee > 0 {
                    row("Late return fee", AppFormat.peso(lateFee))
                }
                Divider().overlay(palette.border)
                HStack {
                    Text("Total")
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Text(AppFormat.peso(totalPrice))
                        .font(.system(size: 16, weight: .heavy))
                }
                .foregroundStyle(palette.text)
            }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(palette.muted)
            Spacer()
            Text(value)
                .font(.system(size: 13))
                .foregroundStyle(palette.text)
        }
    }
}
