import SwiftUI

struct TripTrackingView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var bookings: BookingController
    @EnvironmentObject private var messages: MessageController
    @Binding var path: NavigationPath
    let bookingId: String
    @State private var showCancel = false

    var body: some View {
        Group {
            if let booking = bookings.booking(id: bookingId) {
                content(booking)
            } else if bookings.isLoading {
                LoadingStateView(message: "Loading booking…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(palette.canvas)
            } else {
                Text("Booking not found")
                    .foregroundStyle(palette.muted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(palette.canvas)
            }
        }
        .navigationBarHidden(true)
    }

    private func content(_ booking: Booking) -> some View {
        let isOwner = auth.user.role == .owner
        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    IconCircleButton(systemName: "chevron.left") {
                        if !path.isEmpty { path.removeLast() }
                    }
                    Text("Trip Tracking")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(palette.text)
                        .frame(maxWidth: .infinity)
                    IconCircleButton(systemName: "message") {
                        openChat(for: booking)
                    }
                }

                AppCard {
                    HStack(spacing: 16) {
                        VehicleImageView(vehicle: booking.vehicle, height: 56)
                            .frame(width: 88)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(booking.vehicle.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(palette.text)
                            Text("\(AppFormat.shortDate(booking.startDate)) — \(AppFormat.shortDate(booking.endDate))")
                                .font(.system(size: 13))
                                .foregroundStyle(palette.muted)
                            StatusPill(status: booking.status)
                            PaymentStatusBadge(status: booking.currentPaymentStatus)
                            Text(AppFormat.peso(booking.totalPrice))
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundStyle(palette.text)
                        }
                    }
                }

                TrackingStepper(booking: booking)

                if !isOwner, booking.status == .approved, let pin = booking.pickupPIN {
                    AppCard {
                        VStack(spacing: 8) {
                            Text("Show this PIN to the owner at pickup")
                                .font(.system(size: 13))
                                .foregroundStyle(palette.muted)
                            Text(pin)
                                .font(.system(size: 40, weight: .heavy, design: .rounded))
                                .foregroundStyle(palette.text)
                                .tracking(8)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                if !isOwner,
                   booking.status == .approved,
                   booking.paymentMethod != .cash,
                   booking.currentPaymentStatus == .unpaid || booking.currentPaymentStatus == .rejected {
                    PayNowCardView(booking: booking)
                }

                if booking.isApprovedOrLater, let pickupTime = booking.pickupTime {
                    AppCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Pickup details")
                                .font(.system(size: 13))
                                .foregroundStyle(palette.muted)
                            Text(booking.location)
                                .font(.system(size: 18, weight: .heavy))
                                .foregroundStyle(palette.text)
                            Text(pickupTime)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(palette.yellow)
                            OutlineButton(title: "Open in Maps") {
                                bookings.openInMaps(location: booking.location)
                            }
                            .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                if booking.isApprovedOrLater {
                    AppCard {
                        if isOwner {
                            ContactRow(
                                title: "Renter contact",
                                number: booking.renterContact,
                                onMessage: { openChat(for: booking) }
                            )
                        } else if let ownerContact = booking.ownerContact, !ownerContact.isEmpty {
                            ContactRow(
                                title: "Owner contact",
                                number: ownerContact,
                                onMessage: { openChat(for: booking) }
                            )
                        } else {
                            Text("Owner contact will appear once the booking is approved.")
                                .font(.system(size: 13))
                                .foregroundStyle(palette.muted)
                        }
                    }
                }

                if !booking.photosAtPickup.isEmpty || !booking.photosAtReturn.isEmpty {
                    ConditionPhotosView(booking: booking) { fileName in
                        bookings.fullScreenPhoto = fileName
                    }
                }

                if booking.wasDepositReturned || !booking.depositDeductions.isEmpty {
                    DepositCardView(
                        booking: booking,
                        onMessageOwner: { openChat(for: booking) },
                        onSelectPhoto: { bookings.fullScreenPhoto = $0 }
                    )
                } else {
                    AppCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Charges")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(palette.text)
                            HStack {
                                Text("Security deposit")
                                    .font(.system(size: 13))
                                    .foregroundStyle(palette.muted)
                                Spacer()
                                Text(AppFormat.peso(booking.deposit))
                                    .font(.system(size: 13))
                                    .foregroundStyle(palette.text)
                            }
                            let lateFee = bookings.displayedLateFee(for: booking)
                            HStack {
                                Text("Late return fee")
                                    .font(.system(size: 13))
                                    .foregroundStyle(palette.muted)
                                Spacer()
                                Text(AppFormat.peso(lateFee))
                                    .font(.system(size: 13))
                                    .foregroundStyle(lateFee > 0 ? palette.danger : palette.text)
                            }
                        }
                    }
                }

                if booking.status == .completed {
                    PrimaryButton(title: "View Receipt") {
                        path.append(AppRoute.receipt(booking.id))
                    }
                    if (isOwner && !booking.ownerHasRated) || (!isOwner && !booking.renterHasRated) {
                        PrimaryButton(title: isOwner ? "Rate Renter" : "Rate Trip") {
                            path.append(AppRoute.rateTrip(booking.id))
                        }
                    } else {
                        Text("Thanks — rating submitted.")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(palette.muted)
                    }
                }

                if !isOwner, booking.status == .approved || booking.status == .ongoing {
                    if let pending = booking.pendingExtension {
                        AppCard {
                            Text("Extension pending: +\(pending.extraDays) day\(pending.extraDays == 1 ? "" : "s") (\(AppFormat.peso(pending.extraCost)))")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(palette.text)
                        }
                    } else {
                        OutlineButton(title: "Extend rental") {
                            bookings.beginExtend(bookingId: booking.id)
                        }
                    }
                }

                if !isOwner && booking.canCancel {
                    Button("Cancel Booking") {
                        showCancel = true
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(palette.danger)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                }
            }
            .padding(24)
        }
        .background(palette.canvas.ignoresSafeArea())
        .fullScreenCover(isPresented: Binding(
            get: { bookings.fullScreenPhoto != nil },
            set: { if !$0 { bookings.fullScreenPhoto = nil } }
        )) {
            if let file = bookings.fullScreenPhoto {
                FullScreenPhotoView(fileName: file) {
                    bookings.fullScreenPhoto = nil
                }
            }
        }
        .sheet(isPresented: $bookings.showExtendSheet) {
            ExtendRentalSheet()
        }
        .alert("Cancel Booking?", isPresented: $showCancel) {
            Button("Keep Booking", role: .cancel) {}
            Button("Yes, Cancel", role: .destructive) {
                bookings.cancelBooking(booking.id)
                if !path.isEmpty { path.removeLast() }
            }
        } message: {
            Text("Cancellations within 24 hours of pickup incur a 50% fee.")
        }
    }

    private func openChat(for booking: Booking) {
        let conversation = messages.conversation(for: booking)
        path.append(AppRoute.chat(conversation.id))
    }
}
