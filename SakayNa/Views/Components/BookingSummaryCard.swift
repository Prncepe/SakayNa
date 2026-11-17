import SwiftUI

struct BookingSummaryCard: View {
    @Environment(\.palette) private var palette
    let vehicle: Vehicle
    let startDate: Date
    let endDate: Date
    let location: String

    var body: some View {
        AppCard {
            HStack(spacing: 16) {
                VehicleImageView(vehicle: vehicle, height: 56)
                    .frame(width: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(vehicle.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(palette.text)
                    Text("\(AppFormat.shortDate(startDate)) — \(AppFormat.shortDate(endDate)) · \(location)")
                        .font(.system(size: 13))
                        .foregroundStyle(palette.muted)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(AppFormat.peso(vehicle.pricePerDay))
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundStyle(palette.text)
                        Text("/day")
                            .font(.system(size: 12))
                            .foregroundStyle(palette.muted)
                    }
                }
            }
        }
    }
}
