import SwiftUI

struct ExtendRentalSheet: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var bookings: BookingController
    @EnvironmentObject private var vehicles: VehicleController

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                if let booking = currentBooking {
                    Text("Add 1 to 7 extra days. Extra cost uses the daily rate\(booking.addon ? " and add-on" : "").")
                        .font(.system(size: 13))
                        .foregroundStyle(palette.muted)

                    HStack {
                        Text("Extra days")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(palette.text)
                        Spacer()
                        HStack(spacing: 16) {
                            Button {
                                bookings.extendExtraDays = max(1, bookings.extendExtraDays - 1)
                            } label: {
                                Image(systemName: "minus")
                                    .frame(width: 32, height: 32)
                                    .background(palette.fieldFill)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            Text("\(bookings.extendExtraDays)")
                                .font(.system(size: 20, weight: .heavy))
                                .foregroundStyle(palette.text)
                                .frame(minWidth: 24)
                            Button {
                                bookings.extendExtraDays = min(7, bookings.extendExtraDays + 1)
                            } label: {
                                Image(systemName: "plus")
                                    .frame(width: 32, height: 32)
                                    .background(palette.fieldFill)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack {
                        Text("Extra cost")
                            .font(.system(size: 15))
                            .foregroundStyle(palette.muted)
                        Spacer()
                        Text(AppFormat.peso(bookings.extraCost(for: booking, extraDays: bookings.extendExtraDays)))
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(palette.text)
                    }

                    if let newEnd = Calendar.current.date(byAdding: .day, value: bookings.extendExtraDays, to: booking.endDate) {
                        Text("New end date \(AppFormat.longDate(newEnd))")
                            .font(.system(size: 13))
                            .foregroundStyle(palette.muted)
                    }
                }

                Spacer()

                PrimaryButton(title: "Request extension") {
                    if let booking = currentBooking {
                        let live = vehicles.vehicle(id: booking.vehicle.id) ?? booking.vehicle
                        bookings.requestExtension(vehicle: live)
                    }
                }
            }
            .padding(24)
            .background(palette.canvas)
            .navigationTitle("Extend rental")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { bookings.showExtendSheet = false }
                }
            }
            .alert("Can't extend", isPresented: Binding(
                get: { bookings.overlapAlertMessage != nil },
                set: { if !$0 { bookings.overlapAlertMessage = nil } }
            )) {
                Button("OK", role: .cancel) { bookings.overlapAlertMessage = nil }
            } message: {
                Text(bookings.overlapAlertMessage ?? "")
            }
        }
        .presentationDetents([.medium])
    }

    private var currentBooking: Booking? {
        guard let id = bookings.extendBookingId else { return nil }
        return bookings.booking(id: id)
    }
}
