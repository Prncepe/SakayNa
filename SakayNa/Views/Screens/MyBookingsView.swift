import SwiftUI

struct MyBookingsView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var bookings: BookingController
    @Binding var path: NavigationPath
    @State private var cancelId: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            AppHeader()
            Text("My Bookings")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(palette.text)

            HStack(spacing: 8) {
                ForEach(BookingListTab.allCases, id: \.self) { tab in
                    FilterChip(
                        title: tab.rawValue,
                        isActive: bookings.bookingTab == tab,
                        fillsWidth: true
                    ) {
                        bookings.bookingTab = tab
                    }
                }
            }

            List {
                if bookings.isLoading && bookings.bookings.isEmpty {
                    LoadingStateView(message: "Loading bookings…")
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                } else if bookings.filteredBookings().isEmpty {
                    EmptyStateView(
                        systemImage: "calendar",
                        title: "No bookings yet",
                        message: "You have no \(bookings.bookingTab.rawValue.lowercased()) bookings."
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(bookings.filteredBookings()) { booking in
                        VStack(spacing: 8) {
                            Button {
                                path.append(AppRoute.tripTracking(booking.id))
                            } label: {
                                bookingRow(booking)
                            }
                            .buttonStyle(.plain)

                            if bookings.bookingTab == .upcoming && booking.canCancel {
                                Button("Cancel") {
                                    cancelId = booking.id
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(palette.danger)
                                .frame(maxWidth: .infinity)
                            }

                            if booking.status == .completed {
                                Button("View Receipt") {
                                    path.append(AppRoute.receipt(booking.id))
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(palette.yellow)
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 88)
        .background(palette.canvas.ignoresSafeArea())
        .navigationBarHidden(true)
        .alert("Cancel Booking?", isPresented: Binding(
            get: { cancelId != nil },
            set: { if !$0 { cancelId = nil } }
        )) {
            Button("Keep Booking", role: .cancel) { cancelId = nil }
            Button("Yes, Cancel", role: .destructive) {
                if let id = cancelId {
                    bookings.cancelBooking(id)
                }
                cancelId = nil
            }
        } message: {
            Text("Cancellations within 24 hours of pickup incur a 50% fee.")
        }
    }

    private func bookingRow(_ booking: Booking) -> some View {
        AppCard {
            HStack(alignment: .top, spacing: 16) {
                VehicleImageView(vehicle: booking.vehicle, height: 56)
                    .frame(width: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.vehicle.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(palette.text)
                    Text("\(AppFormat.shortDate(booking.startDate)) — \(AppFormat.shortDate(booking.endDate)) · \(booking.location)")
                        .font(.system(size: 13))
                        .foregroundStyle(palette.muted)
                    HStack(spacing: 6) {
                        StatusPill(status: booking.status)
                        PaymentStatusBadge(status: booking.currentPaymentStatus)
                    }
                }
                Spacer()
                Text(AppFormat.peso(booking.totalPrice))
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(palette.text)
            }
        }
        .opacity(booking.status == .declined || booking.status == .cancelled ? 0.6 : 1)
    }
}
