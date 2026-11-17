import SwiftUI

struct HomeAvailabilityBar: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var vehicles: VehicleController
    @EnvironmentObject private var bookings: BookingController

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                dateColumn(
                    title: "Pickup date",
                    date: Binding(
                        get: { bookings.startDate },
                        set: { bookings.setFilterStartDate($0) }
                    ),
                    range: bookings.earliestStartDate...
                )
                dateColumn(
                    title: "Return date",
                    date: Binding(
                        get: { bookings.endDate },
                        set: { bookings.setFilterEndDate($0) }
                    ),
                    range: bookings.earliestEndDate...
                )
            }

            if bookings.availabilityFilterOn {
                HStack {
                    Text(bookings.availabilityLabel ?? "")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(palette.yellow)
                    Spacer()
                    Button("Clear") {
                        bookings.clearAvailabilityFilter()
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(palette.muted)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CityFilter.allCases, id: \.self) { city in
                        FilterChip(
                            title: city.rawValue,
                            isActive: vehicles.cityFilter == city
                        ) {
                            vehicles.cityFilter = city
                        }
                    }
                }
            }
        }
    }

    private func dateColumn(title: String, date: Binding<Date>, range: PartialRangeFrom<Date>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(1.1)
                .foregroundStyle(palette.muted)
            DatePicker(title, selection: date, in: range, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(palette.yellow)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(palette.fieldFill)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
