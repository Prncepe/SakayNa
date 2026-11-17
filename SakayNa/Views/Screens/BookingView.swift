import SwiftUI

struct BookingView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var vehicles: VehicleController
    @EnvironmentObject private var bookings: BookingController
    @EnvironmentObject private var messages: MessageController
    @Binding var path: NavigationPath
    @State private var showOverlapAlert = false

    var body: some View {
        Group {
            if let vehicle = vehicles.selectedVehicle {
                content(for: vehicle)
            } else {
                Text("No vehicle selected")
                    .foregroundStyle(palette.muted)
            }
        }
        .background(palette.canvas.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $bookings.showTerms) {
            termsSheet
        }
        .alert("Can't book these dates", isPresented: $showOverlapAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(bookings.overlapAlertMessage ?? "Please pick different dates.")
        }
        .onAppear {
            bookings.clampDraftDates()
        }
    }

    private func content(for vehicle: Vehicle) -> some View {
        let total = bookings.totalPrice(vehicle: vehicle, addonPerDay: vehicles.addonPricePerDay)
        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AppHeader(title: "Your Booking", showsBack: true, showsProfileActions: false) {
                    if !path.isEmpty { path.removeLast() }
                }

                BookingSummaryCard(
                    vehicle: vehicle,
                    startDate: bookings.startDate,
                    endDate: bookings.endDate,
                    location: bookings.location
                )

                AppCard {
                    VStack(spacing: 16) {
                        dateRow("RENTAL START", date: startDateBinding)
                        dateRow("RENTAL END", date: endDateBinding)
                        labeledPicker("PICKUP LOCATION", systemImage: "mappin") {
                            Picker("Location", selection: $bookings.location) {
                                ForEach(bookings.pickupLocations, id: \.self) { place in
                                    Text(place).tag(place)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(palette.text)
                        }
                        PillField(
                            label: "CONTACT NUMBER",
                            placeholder: "09XX XXX XXXX",
                            prefix: "🇵🇭 +63",
                            keyboard: .phonePad,
                            text: $bookings.contactNumber
                        )
                    }
                }

                AppCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Choose payment method")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(palette.text)
                        ForEach(PaymentMethod.allCases, id: \.self) { method in
                            PaymentOptionRow(
                                method: method,
                                isSelected: bookings.paymentMethod == method
                            ) {
                                bookings.paymentMethod = method
                            }
                        }
                    }
                }

                if bookings.paymentMethod.usesScanDetails {
                    ScanToPayCard(
                        method: bookings.paymentMethod,
                        ownerName: "Juan Dela Cruz",
                        accountNumber: payoutDetails,
                        qrAvailable: (bookings.paymentMethod == .qrPh || bookings.paymentMethod == .gcash || bookings.paymentMethod == .maya) && auth.hasQR,
                        qrFileName: auth.user.qrFileName
                    )
                }

                if !bookings.blockedDatesText(for: vehicle).isEmpty {
                    Text("Unavailable: \(bookings.blockedDatesText(for: vehicle))")
                        .font(.system(size: 12))
                        .foregroundStyle(palette.danger)
                }

                PriceBreakdownCard(
                    vehicle: vehicle,
                    days: bookings.rentalDays,
                    addonPrice: vehicles.addonPricePerDay * bookings.rentalDays,
                    deposit: vehicle.securityDeposit,
                    totalPrice: total
                )

                HStack(alignment: .top, spacing: 10) {
                    Button {
                        bookings.termsChecked.toggle()
                    } label: {
                        Image(systemName: bookings.termsChecked ? "checkmark.square.fill" : "square")
                            .foregroundStyle(bookings.termsChecked ? palette.yellow : palette.muted)
                    }
                    .buttonStyle(.plain)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("I agree to the")
                            .font(.system(size: 13))
                            .foregroundStyle(palette.muted)
                        Button("Terms & Conditions and Rental Policy") {
                            bookings.showTerms = true
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .underline()
                        .foregroundStyle(palette.text)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(palette.text.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(palette.border, lineWidth: 1)
                )

                if !auth.hasLicense {
                    AppCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("A valid driver's license is required before you can request a booking.")
                                .font(.system(size: 13))
                                .foregroundStyle(palette.muted)
                            OutlineButton(title: "Upload license") {
                                path.append(AppRoute.licenseUpload)
                            }
                        }
                    }
                }

                SlideToConfirm(
                    label: bookings.paymentMethod == .cash
                        ? "Pay on pickup — \(AppFormat.peso(total))"
                        : "Slide to Request — \(AppFormat.peso(total))",
                    isEnabled: bookings.termsChecked && auth.hasLicense
                ) {
                    guard bookings.canConfirmBooking(vehicle: vehicles.vehicle(id: vehicle.id) ?? vehicle) else {
                        showOverlapAlert = true
                        return
                    }
                    bookings.confirmPayment(
                        vehicle: vehicle,
                        addon: vehicles.addonEnabled,
                        addonPricePerDay: vehicles.addonPricePerDay,
                        renterName: auth.user.name,
                        renterId: auth.user.id,
                        licenseRef: auth.user.licenseFileName
                    ) { booking in
                        messages.startOrFind(
                            renterId: auth.user.id,
                            ownerId: vehicle.ownerId,
                            vehicleId: vehicle.id,
                            bookingId: booking.id
                        )
                        path.append(AppRoute.confirmation)
                    } onFailure: {
                        showOverlapAlert = true
                    }
                }
            }
            .padding(24)
        }
    }

    private var startDateBinding: Binding<Date> {
        Binding(
            get: { bookings.startDate },
            set: { bookings.setStartDate($0) }
        )
    }

    private var endDateBinding: Binding<Date> {
        Binding(
            get: { bookings.endDate },
            set: { bookings.setEndDate($0) }
        )
    }

    private var payoutDetails: String {
        switch bookings.paymentMethod {
        case .gcash:
            return auth.user.gcashNumber.isEmpty ? "0917-XXX-XXXX" : auth.user.gcashNumber
        case .maya:
            return auth.user.mayaNumber.isEmpty ? "0917-XXX-XXXX" : auth.user.mayaNumber
        case .bankTransfer:
            return auth.user.bankAccount.isEmpty ? "Account not added yet" : auth.user.bankAccount
        case .qrPh:
            return auth.user.qrPhEnabled ? "QR Ph enabled" : "QR Ph not enabled yet"
        case .cash:
            return ""
        }
    }

    private func labeledPicker<Content: View>(_ label: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .tracking(1.3)
                .foregroundStyle(palette.muted)
                .padding(.leading, 8)
            HStack {
                Image(systemName: systemImage)
                    .foregroundStyle(palette.muted)
                content()
                Spacer()
            }
            .padding(.horizontal, 20)
            .frame(height: 58)
            .background(palette.fieldFill)
            .overlay(Capsule().stroke(palette.border, lineWidth: 1))
            .clipShape(Capsule())
        }
    }

    private func dateRow(_ label: String, date: Binding<Date>) -> some View {
        let range: ClosedRange<Date> = label.contains("START")
            ? bookings.earliestStartDate...Date.distantFuture
            : bookings.earliestEndDate...Date.distantFuture
        return VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .tracking(1.3)
                .foregroundStyle(palette.muted)
                .padding(.leading, 8)
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(palette.muted)
                DatePicker("", selection: date, in: range, displayedComponents: .date)
                    .labelsHidden()
                    .tint(palette.yellow)
                Spacer()
            }
            .padding(.horizontal, 20)
            .frame(height: 58)
            .background(palette.fieldFill)
            .overlay(Capsule().stroke(palette.border, lineWidth: 1))
            .clipShape(Capsule())
        }
    }

    private var termsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(bookings.terms, id: \.self) { term in
                        Text(term)
                            .font(.system(size: 13))
                            .foregroundStyle(palette.muted)
                            .padding(.leading, 12)
                            .overlay(alignment: .leading) {
                                Rectangle().fill(palette.yellow).frame(width: 2)
                            }
                    }
                }
                .padding(24)
            }
            .background(palette.canvas)
            .navigationTitle("Terms & Conditions")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { bookings.showTerms = false }
                }
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(title: "I Agree", action: bookings.agreeToTerms)
                    .padding(24)
            }
        }
        .presentationDetents([.large])
    }
}
