import SwiftUI

struct BookingRequestsView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var bookings: BookingController
    @EnvironmentObject private var messages: MessageController
    @Binding var path: NavigationPath

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            AppHeader()
            Text("Booking Requests")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(palette.text)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(RequestFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.rawValue,
                            isActive: bookings.requestFilter == filter
                        ) {
                            bookings.requestFilter = filter
                        }
                    }
                }
            }

            List {
                if bookings.isLoading && bookings.bookings.isEmpty {
                    LoadingStateView(message: "Loading requests…")
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                } else if bookings.requestedBookings().isEmpty {
                    EmptyStateView(
                        systemImage: "tray",
                        title: "No requests",
                        message: "You have no \(bookings.requestFilter.rawValue.lowercased()) booking requests."
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(bookings.requestedBookings()) { booking in
                        requestCard(booking)
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
        .sheet(isPresented: $bookings.showApproveSheet) {
            approveSheet
        }
        .sheet(isPresented: $bookings.showConditionSheet) {
            ConditionPhotoSheet()
        }
        .sheet(isPresented: $bookings.showPickupPINSheet) {
            PickupPINSheet()
        }
        .sheet(isPresented: $bookings.showDeductionSheet) {
            DepositDeductionsSheet()
        }
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
        .alert("Can't start pickup", isPresented: Binding(
            get: { bookings.actionAlert != nil },
            set: { if !$0 { bookings.actionAlert = nil } }
        )) {
            Button("OK", role: .cancel) { bookings.actionAlert = nil }
        } message: {
            Text(bookings.actionAlert ?? "")
        }
        .confirmationDialog(
            "Reject payment proof?",
            isPresented: $bookings.showRejectProofSheet,
            titleVisibility: .visible
        ) {
            ForEach(PaymentRejectReason.allCases, id: \.self) { reason in
                Button(reason.rawValue, role: .destructive) {
                    bookings.rejectPaymentProof(reason: reason)
                }
            }
            Button("Keep proof", role: .cancel) {}
        }
        .confirmationDialog(
            "Cancel this booking?",
            isPresented: $bookings.showOwnerCancelSheet,
            titleVisibility: .visible
        ) {
            ForEach(OwnerCancelReason.allCases, id: \.self) { reason in
                Button(reason.rawValue, role: .destructive) {
                    bookings.confirmOwnerCancel(reason: reason)
                }
            }
            Button("Keep Booking", role: .cancel) {}
        } message: {
            Text("The renter will be notified with the reason you pick.")
        }
    }

    private func requestCard(_ booking: Booking) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                Button {
                    path.append(AppRoute.tripTracking(booking.id))
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(booking.renterName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(palette.text)
                            Text("\(booking.vehicle.name) · \(AppFormat.shortDate(booking.startDate)) — \(AppFormat.shortDate(booking.endDate))")
                                .font(.system(size: 13))
                                .foregroundStyle(palette.muted)
                            if let pickup = booking.pickupTime {
                                Text("Pickup at \(booking.location), \(pickup)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(palette.yellow)
                            }
                            PaymentStatusBadge(status: booking.currentPaymentStatus)
                        }
                        Spacer()
                        Text(AppFormat.peso(booking.totalPrice))
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundStyle(palette.text)
                    }
                }
                .buttonStyle(.plain)

                if booking.isApprovedOrLater {
                    ContactRow(
                        title: "Renter contact",
                        number: booking.renterContact,
                        onMessage: { openChat(for: booking) }
                    )
                }

                if booking.status == .pending {
                    RenterInfoCard(booking: booking)
                    HStack(spacing: 12) {
                        OutlineButton(title: "Decline") {
                            bookings.declineRequest(booking.id)
                        }
                        PrimaryButton(
                            title: "Approve",
                            isEnabled: auth.user(id: booking.renterId ?? "")?.hasLicensePhoto == true
                        ) {
                            bookings.beginApprove(booking)
                        }
                    }
                }

                if let pending = booking.pendingExtension,
                   booking.status == .approved || booking.status == .ongoing {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Extension request")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(palette.text)
                        Text("+\(pending.extraDays) day\(pending.extraDays == 1 ? "" : "s") · \(AppFormat.peso(pending.extraCost))")
                            .font(.system(size: 13))
                            .foregroundStyle(palette.muted)
                        HStack(spacing: 12) {
                            OutlineButton(title: "Decline") {
                                bookings.declineExtension(booking.id)
                            }
                            PrimaryButton(title: "Approve") {
                                bookings.approveExtension(booking.id)
                            }
                        }
                    }
                }

                if booking.status == .approved {
                    VStack(spacing: 12) {
                        if booking.paymentMethod != .cash, booking.currentPaymentStatus == .proofSubmitted {
                            paymentProofBlock(booking)
                        }
                        if booking.paymentMethod == .cash, !booking.isPaid {
                            PrimaryButton(title: "Cash received") {
                                bookings.markCashReceived(booking.id)
                            }
                        }
                        PrimaryButton(
                            title: "Mark as Picked Up",
                            systemImage: "shippingbox.fill",
                            isEnabled: booking.isPaid
                        ) {
                            bookings.beginPickup(bookingId: booking.id)
                        }
                        Button("Cancel booking") {
                            bookings.beginOwnerCancel(booking.id)
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(palette.danger)
                        .frame(maxWidth: .infinity)
                    }
                }

                if booking.status == .ongoing {
                    PrimaryButton(title: "Mark as Returned", systemImage: "checkmark") {
                        bookings.beginCondition(action: .returnVehicle, bookingId: booking.id)
                    }
                }

                if booking.status == .completed && !booking.ownerHasRated {
                    PrimaryButton(title: "Rate Renter") {
                        path.append(AppRoute.rateTrip(booking.id))
                    }
                }
            }
        }
    }

    private var approveSheet: some View {
        NavigationStack {
            Form {
                Section("Pickup details") {
                    TextField("Pickup location", text: $bookings.approveLocation)
                    TextField("Pickup time", text: $bookings.approveTime)
                }
            }
            .scrollContentBackground(.hidden)
            .background(palette.canvas)
            .navigationTitle("Approve Booking")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { bookings.showApproveSheet = false }
                }
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(title: "Confirm Approve") {
                    if let booking = bookings.confirmApprove(ownerPhone: auth.user.phone) {
                        let conversation = messages.conversation(for: booking)
                        messages.send(
                            conversationId: conversation.id,
                            senderId: auth.user.id,
                            text: "Hi! Your booking for \(booking.vehicle.name) is confirmed. Pickup at \(booking.location) at \(booking.pickupTime ?? ""). Looking forward to your rental!"
                        )
                    }
                }
                    .padding(24)
            }
        }
        .presentationDetents([.medium])
    }

    private func paymentProofBlock(_ booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Payment proof")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(palette.text)
            Text("Reference: \(booking.paymentReference ?? "—")")
                .font(.system(size: 13))
                .foregroundStyle(palette.muted)
            if let file = booking.paymentProofFile {
                Button {
                    bookings.fullScreenPhoto = file
                } label: {
                    StoredImage(fileName: file, contentMode: .fill)
                        .frame(height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            HStack(spacing: 12) {
                OutlineButton(title: "Reject proof") {
                    bookings.beginRejectProof(booking.id)
                }
                PrimaryButton(title: "Payment received") {
                    bookings.markPaymentReceived(booking.id)
                }
            }
        }
    }

    private func openChat(for booking: Booking) {
        let conversation = messages.conversation(for: booking)
        path.append(AppRoute.chat(conversation.id))
    }
}
