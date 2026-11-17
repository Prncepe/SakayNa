import Foundation
import Combine
import UIKit
import FirebaseFirestore

final class BookingController: ObservableObject {
    @Published var bookings: [Booking] = []
    @Published var notifications: [AppNotification] = []
    @Published var bookingTab: BookingListTab = .upcoming
    @Published var startDate = Date()
    @Published var endDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @Published var location = "Lucena"
    @Published var paymentMethod: PaymentMethod = .gcash
    @Published var contactNumber = ""
    @Published var termsChecked = false
    @Published var showTerms = false
    @Published var showNotifications = false
    @Published var selectedTab: MainTab = .home
    @Published var lastConfirmedTotal = 0
    @Published var homeResetToken = 0
    @Published var bookingsResetToken = 0
    @Published var profileResetToken = 0
    @Published var messagesResetToken = 0
    @Published var pendingDestination: AppRoute?
    @Published var islandNotification: AppNotification?
    @Published var overlapAlertMessage: String?
    @Published var showOwnerCancelSheet = false
    @Published var ownerCancelBookingId: String?
    @Published var availabilityFilterOn = false
    @Published var unavailableVehicleIds: Set<String> = []
    @Published var isLoading = false
    @Published var isLoadingNotifications = false
    @Published var isCheckingAvailability = false
    @Published var isSaving = false
    @Published var alertMessage: String?
    private var uid: String?
    private var renterListener: ListenerRegistration?
    private var ownerListener: ListenerRegistration?
    private var renterBookings: [Booking] = []
    private var ownerBookings: [Booking] = []
    private var pins: [String: String] = [:]
    private var pinRequests: Set<String> = []
    private var reminderKeys: [String: String] = [:]
    private var notificationsListener: ListenerRegistration?
    private var loadedLists = Set<String>()
    private var loginTime = Date()

    // MARK: - Listeners

    func start(uid: String) {
        stop()
        self.uid = uid
        isLoading = true
        isLoadingNotifications = true
        loadedLists = []
        renterListener = BookingService.listen(field: "renterId", uid: uid) { [weak self] list in
            self?.renterBookings = list
            self?.loadedLists.insert("renter")
            self?.mergeBookings()
        } onError: { [weak self] error in
            self?.showLoadError(error)
        }
        ownerListener = BookingService.listen(field: "ownerId", uid: uid) { [weak self] list in
            self?.ownerBookings = list
            self?.loadedLists.insert("owner")
            self?.mergeBookings()
        } onError: { [weak self] error in
            self?.showLoadError(error)
        }
        loginTime = Date()
        notificationsListener = NotificationService.listen(uid: uid) { [weak self] all, added in
            self?.isLoadingNotifications = false
            self?.handleNotifications(all: all, added: added)
        } onError: { [weak self] error in
            self?.isLoadingNotifications = false
            self?.alertMessage = "Couldn't load notifications. \(error.localizedDescription)"
        }
    }

    func stop() {
        renterListener?.remove()
        ownerListener?.remove()
        notificationsListener?.remove()
        renterListener = nil
        ownerListener = nil
        notificationsListener = nil
        notifications = []
        islandNotification = nil
        uid = nil
        renterBookings = []
        ownerBookings = []
        bookings = []
        pins = [:]
        pinRequests = []
        reminderKeys = [:]
        unavailableVehicleIds = []
        isLoading = false
        isLoadingNotifications = false
        loadedLists = []
        LocalNotificationService.shared.cancelAllBookingReminders()
    }

    private func showLoadError(_ error: Error) {
        isLoading = false
        alertMessage = "Couldn't load bookings. \(error.localizedDescription)"
    }

    private func mergeBookings() {
        var byId: [String: Booking] = [:]
        for booking in renterBookings + ownerBookings {
            byId[booking.id] = booking
        }
        var merged = byId.values.sorted { $0.startDate > $1.startDate }
        for index in merged.indices {
            merged[index].pickupPIN = pins[merged[index].id]
        }
        bookings = merged
        isLoading = loadedLists.count < 2
        loadMissingPINs()
        syncRemindersFromSnapshot()
    }

    // Only the renter can read bookings/{id}/private/pin.
    private func loadMissingPINs() {
        guard let uid else { return }
        for booking in bookings where booking.renterId == uid
            && pins[booking.id] == nil
            && !pinRequests.contains(booking.id)
            && (booking.status == .pending || booking.status == .approved) {
            pinRequests.insert(booking.id)
            Task { @MainActor in
                if let pin = await BookingService.loadPIN(bookingId: booking.id) {
                    pins[booking.id] = pin
                    if let index = bookings.firstIndex(where: { $0.id == booking.id }) {
                        bookings[index].pickupPIN = pin
                    }
                }
            }
        }
    }

    // Reminders stay local. They follow the booking snapshot, so an approval or
    // extension made on the other phone still schedules them here.
    private func syncRemindersFromSnapshot() {
        for booking in bookings {
            let active = booking.status == .approved || booking.status == .ongoing
            let key = active
                ? "\(booking.status.rawValue)|\(booking.endDate.timeIntervalSince1970)|\(booking.pickupTime ?? "")"
                : "off"
            guard reminderKeys[booking.id] != key else { continue }
            let wasActive = reminderKeys[booking.id].map { $0 != "off" } ?? false
            reminderKeys[booking.id] = key
            if active {
                LocalNotificationService.shared.scheduleBookingReminders(for: booking)
            } else if wasActive {
                LocalNotificationService.shared.cancelBookingReminders(bookingId: booking.id)
            }
        }
    }

    private func persist(_ id: String, _ fields: [String]) {
        guard let booking = booking(id: id) else { return }
        Task { @MainActor in
            do {
                try await BookingService.update(booking, fields: fields)
            } catch {
                alertMessage = "Couldn't update the booking. \(error.localizedDescription)"
            }
        }
    }

    private func releaseDays(_ id: String) {
        guard let booking = booking(id: id) else { return }
        Task {
            await BookingService.releaseDays(vehicleId: booking.vehicle.id, bookingId: booking.id)
        }
    }

    private func uploadBookingPhoto(_ image: UIImage, bookingId: String?, onSaved: @escaping (String) -> Void) {
        guard let bookingId else { return }
        isSaving = true
        Task { @MainActor in
            do {
                let reference = try await PhotoService.save(image, path: "bookings/\(bookingId)/photos/\(UUID().uuidString)")
                onSaved(reference)
            } catch {
                alertMessage = "Couldn't upload the photo. \(error.localizedDescription)"
            }
            isSaving = false
        }
    }

    let pickupLocations = ["Lucena", "Lipa", "Batangas City", "Manila"]

    let terms: [String] = [
        "Renter must present a valid driver's license matching the account name at pickup.",
        "Vehicle must be returned with the same fuel level as at pickup, or a refueling fee applies.",
        "Late returns beyond 1 hour incur an additional hourly charge equal to 20% of the daily rate.",
        "Renter is responsible for any damage beyond normal wear and tear during the rental period.",
        "Cancellations made more than 24 hours before pickup receive a full refund; within 24 hours, a 50% cancellation fee applies.",
        "SakayNa is a platform connecting renters and vehicle owners and is not itself the vehicle owner or insurer."
    ]

    let faqs: [(question: String, answer: String)] = [
        (
            "How do I cancel a booking?",
            "You can cancel up to 24 hours before your trip starts for a full refund. Go to My Bookings, select the booking, and tap Cancel."
        ),
        (
            "What if the vehicle breaks down?",
            "Contact your host immediately. If unresolved, our support team is available 24/7."
        ),
        (
            "Are there late return fees?",
            "Yes, returning a vehicle late may incur additional hourly charges to compensate the host."
        )
    ]

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    var rentalDays: Int {
        let start = Calendar.current.startOfDay(for: startDate)
        let end = Calendar.current.startOfDay(for: endDate)
        let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 1
        return max(days, 1)
    }

    var datesAreValid: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let start = Calendar.current.startOfDay(for: startDate)
        let end = Calendar.current.startOfDay(for: endDate)
        return start >= today && end > start
    }

    var earliestStartDate: Date {
        Calendar.current.startOfDay(for: Date())
    }

    var earliestEndDate: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: startDate)) ?? startDate
    }

    func setStartDate(_ date: Date) {
        let today = Calendar.current.startOfDay(for: Date())
        startDate = max(Calendar.current.startOfDay(for: date), today)
        if Calendar.current.startOfDay(for: endDate) <= startDate {
            endDate = earliestEndDate
        }
    }

    func setEndDate(_ date: Date) {
        let proposed = Calendar.current.startOfDay(for: date)
        endDate = proposed <= startDate ? earliestEndDate : proposed
    }

    func clampDraftDates() {
        setStartDate(startDate)
        setEndDate(endDate)
    }

    func setFilterStartDate(_ date: Date) {
        availabilityFilterOn = true
        setStartDate(date)
        refreshAvailability()
    }

    func setFilterEndDate(_ date: Date) {
        availabilityFilterOn = true
        setEndDate(date)
        refreshAvailability()
    }

    func clearAvailabilityFilter() {
        availabilityFilterOn = false
        unavailableVehicleIds = []
    }

    func refreshAvailability() {
        guard availabilityFilterOn else { return }
        let start = startDate
        let end = endDate
        isCheckingAvailability = true
        Task { @MainActor in
            do {
                unavailableVehicleIds = try await BookingService.unavailableVehicleIds(from: start, to: end)
            } catch {
                print("Availability query failed (open the index link if shown): \(error)")
                alertMessage = "Couldn't check availability. \(error.localizedDescription)"
            }
            isCheckingAvailability = false
        }
    }

    var availabilityLabel: String? {
        guard availabilityFilterOn else { return nil }
        return "Available \(AppFormat.shortDate(startDate)) to \(AppFormat.shortDate(endDate))"
    }

    func isVehicleAvailable(_ vehicle: Vehicle) -> Bool {
        guard availabilityFilterOn else { return true }
        return !unavailableVehicleIds.contains(vehicle.id)
            && !hasOverlappingBooking(vehicleId: vehicle.id)
            && !hasBlockedDates(vehicle: vehicle)
    }

    func setEndDateFromDays(_ days: Int) {
        let start = Calendar.current.startOfDay(for: startDate)
        endDate = Calendar.current.date(byAdding: .day, value: max(days, 1), to: start) ?? endDate
    }

    func hasOverlappingBooking(vehicleId: String, start: Date? = nil, end: Date? = nil) -> Bool {
        let blocking: Set<BookingStatus> = [.pending, .approved, .ongoing]
        let start = Calendar.current.startOfDay(for: start ?? startDate)
        let end = Calendar.current.startOfDay(for: end ?? endDate)
        return bookings.contains { booking in
            guard booking.vehicle.id == vehicleId, blocking.contains(booking.status) else { return false }
            let otherStart = Calendar.current.startOfDay(for: booking.startDate)
            let otherEnd = Calendar.current.startOfDay(for: booking.endDate)
            return start < otherEnd && end > otherStart
        }
    }

    func occupiedDateKeys(from start: Date, to end: Date) -> [String] {
        var keys: [String] = []
        var day = Calendar.current.startOfDay(for: start)
        let last = Calendar.current.startOfDay(for: end)
        while day < last {
            keys.append(Vehicle.dateKey(for: day))
            guard let next = Calendar.current.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return keys
    }

    func hasBlockedDates(vehicle: Vehicle, start: Date? = nil, end: Date? = nil) -> Bool {
        let occupied = Set(occupiedDateKeys(from: start ?? startDate, to: end ?? endDate))
        return !occupied.isDisjoint(with: Set(vehicle.blockedDateKeys))
    }

    func blockedDatesText(for vehicle: Vehicle) -> String {
        let dates = vehicle.blockedDateKeys.compactMap { Vehicle.date(fromKey: $0) }.sorted()
        guard !dates.isEmpty else { return "" }
        return dates.map { AppFormat.shortDate($0) }.joined(separator: ", ")
    }

    func canConfirmBooking(vehicle: Vehicle) -> Bool {
        guard datesAreValid else {
            overlapAlertMessage = "Please pick a start date today or later, and an end date after the start date."
            return false
        }
        guard !hasOverlappingBooking(vehicleId: vehicle.id) else {
            overlapAlertMessage = "This vehicle is already booked for those dates. Please pick different dates."
            return false
        }
        guard !hasBlockedDates(vehicle: vehicle) else {
            overlapAlertMessage = "The owner blocked some of those dates. Please pick different dates."
            return false
        }
        return true
    }

    func filteredBookings() -> [Booking] {
        switch bookingTab {
        case .upcoming:
            return bookings.filter { $0.status == .pending || $0.status == .approved }
        case .ongoing:
            return bookings.filter { $0.status == .ongoing }
        case .completed:
            return bookings.filter { $0.status == .completed || $0.status == .declined || $0.status == .cancelled }
        }
    }

    func prepareDraft(days: Int, contact: String) {
        termsChecked = false
        paymentMethod = .gcash
        contactNumber = contact
        guard !availabilityFilterOn else { return }
        startDate = Date()
        endDate = Calendar.current.date(byAdding: .day, value: max(days, 1), to: startDate) ?? startDate
    }

    func totalPrice(vehicle: Vehicle, addonPerDay: Int) -> Int {
        vehicle.pricePerDay * rentalDays + addonPerDay * rentalDays + vehicle.securityDeposit
    }

    func computedLateFee(for booking: Booking, returnedAt: Date = Date()) -> Int {
        let calendar = Calendar.current
        let end = calendar.startOfDay(for: booking.endDate)
        let returned = calendar.startOfDay(for: returnedAt)
        let extra = calendar.dateComponents([.day], from: end, to: returned).day ?? 0
        guard extra > 0 else { return 0 }
        let perDay = Int((Double(booking.vehicle.pricePerDay) * 1.2).rounded())
        return extra * perDay
    }

    func displayedLateFee(for booking: Booking) -> Int {
        if booking.status == .completed {
            return booking.lateReturnFee
        }
        return computedLateFee(for: booking)
    }

    func receiptText(for booking: Booking) -> String {
        let addonTotal = booking.addonPrice * booking.days
        let total = booking.totalPrice + booking.lateReturnFee
        return """
        SakayNa Receipt
        Booking ID: \(booking.id)
        Vehicle: \(booking.vehicle.name)
        Dates: \(AppFormat.longDate(booking.startDate)) — \(AppFormat.longDate(booking.endDate))
        Rate: \(AppFormat.peso(booking.vehicle.pricePerDay)) × \(booking.days) day\(booking.days == 1 ? "" : "s")
        Extensions: \(booking.approvedExtraDays) extra day\(booking.approvedExtraDays == 1 ? "" : "s")
        Add-ons: \(AppFormat.peso(addonTotal))
        Security deposit: \(AppFormat.peso(booking.deposit))
        Deductions: \(AppFormat.peso(booking.deductionsTotal))
        Deposit refund: \(AppFormat.peso(booking.depositRefund))
        Late return fee: \(AppFormat.peso(booking.lateReturnFee))
        Total: \(AppFormat.peso(total))
        Payment method: \(booking.paymentMethod.rawValue)
        Payment status: \(booking.currentPaymentStatus.rawValue)
        \(booking.paymentReference.map { "Payment reference: \($0)" } ?? "")
        """
    }

    // Creates the booking and its day documents in one transaction. The renter
    // makes the pickup PIN here: the booking keeps only its hash.
    func confirmPayment(
        vehicle: Vehicle,
        addon: Bool,
        addonPricePerDay: Int,
        renterName: String,
        renterId: String,
        licenseRef: String?,
        onSuccess: @escaping (Booking) -> Void,
        onFailure: @escaping () -> Void
    ) {
        let total = totalPrice(vehicle: vehicle, addonPerDay: addonPricePerDay)
        let contact = contactNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let bookingId = UUID().uuidString
        let pin = String(format: "%04d", Int.random(in: 0...9999))
        var booking = Booking(
            id: bookingId,
            vehicle: vehicle,
            startDate: startDate,
            endDate: endDate,
            days: rentalDays,
            addon: addon,
            addonPrice: addonPricePerDay,
            totalPrice: total,
            status: .pending,
            location: location,
            paymentMethod: paymentMethod,
            renterName: renterName,
            renterId: renterId,
            renterContact: contact.isEmpty ? "0917XXXXXXX" : contact,
            ownerContact: nil,
            pickupTime: nil,
            messages: [],
            depositAmount: vehicle.securityDeposit,
            depositReturned: false,
            lateFee: 0,
            paymentStatus: .unpaid,
            pickupPINVerified: false
        )
        booking.ownerId = vehicle.ownerId
        booking.pickupPINHash = BookingService.hashPIN(pin, bookingId: bookingId)
        let dayKeys = occupiedDateKeys(from: startDate, to: endDate)
        let newBooking = booking

        isSaving = true
        Task { @MainActor in
            var booking = newBooking
            do {
                try await BookingService.create(booking, dayKeys: dayKeys)
            } catch {
                isSaving = false
                overlapAlertMessage = error.localizedDescription
                onFailure()
                return
            }
            pins[bookingId] = pin
            do {
                try await BookingService.savePIN(pin, bookingId: bookingId)
            } catch {
                alertMessage = "Booking saved, but the pickup PIN couldn't be saved. \(error.localizedDescription)"
            }
            if let licenseRef, let image = try? await PhotoService.load(licenseRef),
               let copy = try? await PhotoService.save(image, path: "bookings/\(bookingId)/photos/license") {
                booking.renterLicenseRef = copy
                try? await BookingService.update(booking, fields: ["renterLicenseRef"])
            }
            isSaving = false
            booking.pickupPIN = pin
            lastConfirmedTotal = total
            termsChecked = false
            addNotification(
                "New booking request for \(vehicle.name) from \(renterName).",
                bookingId: bookingId,
                recipientId: vehicle.ownerId
            )
            onSuccess(booking)
        }
    }

    // Sends the notification to the other person: for a booking, whichever of
    // renter/owner isn't the signed-in user. at: is kept for older call sites.
    func addNotification(
        _ message: String,
        bookingId: String? = nil,
        conversationId: String? = nil,
        recipientId: String? = nil,
        at index: Int = 0
    ) {
        guard let uid else { return }
        var recipient = recipientId
        if recipient == nil, let bookingId, let booking = booking(id: bookingId) {
            recipient = booking.renterId == uid ? booking.ownerId : booking.renterId
        }
        guard let recipient, !recipient.isEmpty, recipient != uid else { return }
        let item = AppNotification(
            id: UUID().uuidString,
            message: message,
            isRead: false,
            timestamp: Date(),
            bookingId: bookingId,
            conversationId: conversationId,
            createdBy: uid
        )
        Task { @MainActor in
            do {
                try await NotificationService.send(item, to: recipient)
            } catch {
                alertMessage = "Couldn't send the notification. \(error.localizedDescription)"
            }
        }
    }

    // New notifications that arrive after login drop the island and, if the
    // app is in the background but still running, show a phone banner.
    private func handleNotifications(all: [AppNotification], added: [AppNotification]) {
        notifications = all
        let fresh = added
            .filter { $0.timestamp > loginTime && !$0.isRead }
            .sorted { $0.timestamp > $1.timestamp }
        guard let newest = fresh.first else { return }
        islandNotification = newest
        for item in fresh {
            LocalNotificationService.shared.fire(title: item.bannerTitle, body: item.message)
        }
    }

    func dismissIsland() {
        islandNotification = nil
    }

    func markNotificationRead(_ id: String) {
        guard let uid, let index = notifications.firstIndex(where: { $0.id == id }),
              !notifications[index].isRead else { return }
        notifications[index].isRead = true
        Task { try? await NotificationService.markRead(uid: uid, notificationId: id) }
    }

    func openNotification(_ id: String) {
        markNotificationRead(id)
        showNotifications = false
        guard let item = notifications.first(where: { $0.id == id }) else { return }
        if let conversationId = item.conversationId {
            selectedTab = .messages
            pendingDestination = .chat(conversationId)
        } else if let bookingId = item.bookingId {
            selectedTab = .bookings
            pendingDestination = .tripTracking(bookingId)
        }
    }

    func agreeToTerms() {
        termsChecked = true
        showTerms = false
    }

    func goToBookingsTab() {
        homeResetToken += 1
        bookingsResetToken += 1
        selectedTab = .bookings
    }

    func goToHomeTab() {
        homeResetToken += 1
        selectedTab = .home
    }

    @Published var requestFilter: RequestFilter = .pending
    @Published var showApproveSheet = false
    @Published var approveBookingId: String?
    @Published var approveLocation = ""
    @Published var approveTime = "10:00 AM"
    @Published var showConditionSheet = false
    @Published var conditionAction: ConditionAction?
    @Published var conditionPhotos: [String: String] = [:]
    @Published var conditionFuel: FuelLevel = .full
    @Published var conditionNote = ""
    @Published var conditionBookingId: String?
    @Published var trackingBookingId: String?
    @Published var showPickupPINSheet = false
    @Published var showExtendSheet = false
    @Published var extendBookingId: String?
    @Published var extendExtraDays = 1
    @Published var pickupPINDraft = ""
    @Published var pickupPINError: String?
    @Published var actionAlert: String?
    @Published var showDeductionSheet = false
    @Published var deductionBookingId: String?
    @Published var draftDeductionAmount = ""
    @Published var draftDeductionReason = ""
    @Published var draftDeductionPhoto: String?
    @Published var paymentReferenceDraft = ""
    @Published var paymentProofDraft: String?
    @Published var paymentProofError: String?
    @Published var showRejectProofSheet = false
    @Published var rejectProofBookingId: String?
    @Published var fullScreenPhoto: String?

    func requestedBookings() -> [Booking] {
        bookings.filter { requestFilter.matchingStatuses.contains($0.status) }
    }

    func booking(id: String) -> Booking? {
        bookings.first { $0.id == id }
    }

    var monthlyCompletedBookings: [Booking] {
        let calendar = Calendar.current
        let now = Date()
        return bookings.filter { booking in
            booking.status == .completed && calendar.isDate(booking.endDate, equalTo: now, toGranularity: .month)
        }
    }

    var totalEarnings: Int {
        monthlyCompletedBookings.reduce(0) { sum, booking in
            sum + booking.totalPrice
                - (booking.wasDepositReturned ? booking.depositRefund : 0)
                + booking.lateReturnFee
        }
    }

    func ownerRatingSummary(ownerId: String) -> (text: String, count: Int) {
        let scores = bookings.compactMap { booking -> Int? in
            guard booking.vehicle.ownerId == ownerId else { return nil }
            return booking.ownerRating
        }
        guard !scores.isEmpty else { return ("New", 0) }
        let average = Double(scores.reduce(0, +)) / Double(scores.count)
        return (String(format: "%.1f", average), scores.count)
    }

    func openInMaps(location: String) {
        var components = URLComponents(string: "https://maps.apple.com/")
        components?.queryItems = [
            URLQueryItem(name: "q", value: "\(location), Philippines")
        ]
        if let url = components?.url {
            UIApplication.shared.open(url)
        }
    }

    var activeBookingCount: Int {
        bookings.filter { $0.status == .approved || $0.status == .upcoming || $0.status == .ongoing }.count
    }

    var pendingRequestCount: Int {
        bookings.filter { $0.status == .pending }.count
    }

    func resetToHome() {
        selectedTab = .home
        showNotifications = false
        islandNotification = nil
        pendingDestination = nil
        homeResetToken += 1
        bookingsResetToken += 1
        profileResetToken += 1
        messagesResetToken += 1
    }

    func beginApprove(_ booking: Booking) {
        approveBookingId = booking.id
        approveLocation = booking.location
        approveTime = booking.pickupTime ?? "10:00 AM"
        showApproveSheet = true
    }

    @discardableResult
    func confirmApprove(ownerPhone: String) -> Booking? {
        guard let id = approveBookingId, let index = bookings.firstIndex(where: { $0.id == id }) else { return nil }
        let vehicleName = bookings[index].vehicle.name
        bookings[index].status = .approved
        bookings[index].location = approveLocation
        bookings[index].pickupTime = approveTime
        bookings[index].ownerContact = ownerPhone
        bookings[index].pickupPINVerified = false
        if bookings[index].paymentMethod == .cash {
            bookings[index].paymentStatus = .unpaid
        }
        persist(id, ["status", "location", "pickupTime", "ownerContact", "pickupPINVerified", "paymentStatus"])
        addNotification("Your booking for \(vehicleName) is approved.", bookingId: id)
        addNotification(
            "Pickup set for \(vehicleName): \(approveLocation) at \(approveTime). Vehicle is ready for pickup.",
            bookingId: id,
            at: 1
        )
        showApproveSheet = false
        approveBookingId = nil
        LocalNotificationService.shared.scheduleBookingReminders(for: bookings[index])
        return bookings[index]
    }

    func declineRequest(_ id: String) {
        guard let index = bookings.firstIndex(where: { $0.id == id }) else { return }
        bookings[index].status = .declined
        LocalNotificationService.shared.cancelBookingReminders(bookingId: id)
        persist(id, ["status"])
        releaseDays(id)
    }

    func beginPickup(bookingId: String) {
        guard let booking = booking(id: bookingId) else { return }
        guard booking.isPaid else {
            actionAlert = "Mark payment as received before pickup."
            return
        }
        conditionBookingId = bookingId
        if booking.pinWasVerified {
            beginCondition(action: .pickup, bookingId: bookingId)
        } else {
            pickupPINDraft = ""
            pickupPINError = nil
            showPickupPINSheet = true
        }
    }

    func verifyPickupPIN() {
        guard let id = conditionBookingId,
              let index = bookings.firstIndex(where: { $0.id == id }) else { return }
        let entered = pickupPINDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let expectedHash = bookings[index].pickupPINHash ?? ""
        if entered.count == 4, BookingService.hashPIN(entered, bookingId: id) == expectedHash {
            bookings[index].pickupPINVerified = true
            persist(id, ["pickupPINVerified"])
            pickupPINError = nil
            showPickupPINSheet = false
            beginCondition(action: .pickup, bookingId: id)
        } else {
            pickupPINError = "Wrong PIN. Ask the renter to show it again."
        }
    }

    func beginCondition(action: ConditionAction, bookingId: String) {
        conditionAction = action
        conditionBookingId = bookingId
        conditionPhotos = [:]
        conditionFuel = .full
        conditionNote = ""
        showConditionSheet = true
    }

    func saveConditionPhoto(side: ConditionSide, image: UIImage) {
        uploadBookingPhoto(image, bookingId: conditionBookingId) { [weak self] reference in
            self?.conditionPhotos[side.rawValue] = reference
        }
    }

    var canConfirmCondition: Bool {
        ConditionSide.allCases.allSatisfy { conditionPhotos[$0.rawValue] != nil }
    }

    func confirmCondition() {
        guard canConfirmCondition,
              let id = conditionBookingId,
              let index = bookings.firstIndex(where: { $0.id == id }) else { return }
        let name = bookings[index].vehicle.name
        if conditionAction == .pickup {
            bookings[index].pickupPhotos = conditionPhotos
            bookings[index].pickupNote = conditionNote
            bookings[index].pickupFuel = conditionFuel.rawValue
            bookings[index].status = .ongoing
            persist(id, ["pickupPhotos", "pickupNote", "pickupFuel", "status"])
            addNotification("Your rental for \(name) is now active. Enjoy your ride!", bookingId: id)
            showConditionSheet = false
            conditionBookingId = nil
            conditionAction = nil
            conditionNote = ""
            conditionPhotos = [:]
        } else {
            bookings[index].returnPhotos = conditionPhotos
            bookings[index].returnNote = conditionNote
            bookings[index].returnFuel = conditionFuel.rawValue
            bookings[index].lateFee = computedLateFee(for: bookings[index])
            bookings[index].depositReturned = true
            bookings[index].depositRefundAmount = bookings[index].deposit
            bookings[index].status = .completed
            persist(id, ["returnPhotos", "returnNote", "returnFuel", "lateFee", "depositReturned", "depositRefundAmount", "status"])
            releaseDays(id)
            LocalNotificationService.shared.cancelBookingReminders(bookingId: id)
            addNotification("Your rental for \(name) has ended. Rate your experience!", bookingId: id)
            showConditionSheet = false
            deductionBookingId = id
            conditionAction = nil
            conditionNote = ""
            conditionPhotos = [:]
            draftDeductionAmount = ""
            draftDeductionReason = ""
            draftDeductionPhoto = nil
            showDeductionSheet = true
        }
    }

    func markPickedUp(_ id: String) {
        guard let index = bookings.firstIndex(where: { $0.id == id }) else { return }
        let name = bookings[index].vehicle.name
        bookings[index].status = .ongoing
        persist(id, ["status"])
        addNotification("Your \(name) is ready — pickup confirmed. Your rental is now ongoing.", bookingId: id)
    }

    func markReturned(_ id: String) {
        guard let index = bookings.firstIndex(where: { $0.id == id }) else { return }
        let name = bookings[index].vehicle.name
        bookings[index].lateFee = computedLateFee(for: bookings[index])
        bookings[index].depositReturned = true
        bookings[index].status = .completed
        persist(id, ["lateFee", "depositReturned", "status"])
        releaseDays(id)
        LocalNotificationService.shared.cancelBookingReminders(bookingId: id)
        addNotification("Your rental for \(name) has ended. Rate your experience!", bookingId: id)
    }

    func cancelBooking(_ id: String) {
        guard let index = bookings.firstIndex(where: { $0.id == id }), bookings[index].canCancel else { return }
        let name = bookings[index].vehicle.name
        bookings[index].status = .cancelled
        persist(id, ["status"])
        releaseDays(id)
        LocalNotificationService.shared.cancelBookingReminders(bookingId: id)
        addNotification("Booking for \(name) was cancelled.", bookingId: id)
    }

    func reasonIfDeleteBlocked(vehicleId: String) -> String? {
        let blocking: Set<BookingStatus> = [.pending, .approved, .ongoing]
        let hits = bookings.filter { $0.vehicle.id == vehicleId && blocking.contains($0.status) }
        guard !hits.isEmpty else { return nil }
        let labels = Array(Set(hits.map(\.status.rawValue))).sorted().joined(separator: ", ")
        return "This vehicle has \(labels) booking(s). Finish or cancel those bookings before deleting it."
    }

    func beginOwnerCancel(_ id: String) {
        guard let booking = booking(id: id), booking.status == .approved else { return }
        ownerCancelBookingId = id
        showOwnerCancelSheet = true
    }

    func confirmOwnerCancel(reason: OwnerCancelReason) {
        guard let id = ownerCancelBookingId,
              let index = bookings.firstIndex(where: { $0.id == id }),
              bookings[index].status == .approved else { return }
        let name = bookings[index].vehicle.name
        bookings[index].status = .cancelled
        bookings[index].cancelReason = reason.rawValue
        persist(id, ["status", "cancelReason"])
        releaseDays(id)
        LocalNotificationService.shared.cancelBookingReminders(bookingId: id)
        addNotification(
            "Your booking for \(name) was cancelled. Reason: \(reason.rawValue).",
            bookingId: id
        )
        ownerCancelBookingId = nil
        showOwnerCancelSheet = false
    }

    func saveRenterRatings(bookingId: String, vehicleRating: Int, ownerRating: Int, comment: String) {
        guard let index = bookings.firstIndex(where: { $0.id == bookingId }) else { return }
        let alreadyRated = bookings[index].ownerRating != nil
        bookings[index].vehicleRating = vehicleRating
        bookings[index].ownerRating = ownerRating
        bookings[index].ratingComment = comment
        persist(bookingId, ["vehicleRating", "ownerRating", "ratingComment"])
        let ownerId = bookings[index].ownerId
        if !alreadyRated, !ownerId.isEmpty {
            addUserRating(uid: ownerId, stars: ownerRating)
        }
    }

    private func addUserRating(uid: String, stars: Int) {
        Task { @MainActor in
            do {
                try await BookingService.addUserRating(uid: uid, stars: stars)
            } catch {
                alertMessage = "Couldn't save the rating. \(error.localizedDescription)"
            }
        }
    }

    func reasonIfAccountDeleteBlocked(userId: String) -> String? {
        let blocking: Set<BookingStatus> = [.pending, .approved, .ongoing]
        let hits = bookings.contains { booking in
            guard blocking.contains(booking.status) else { return false }
            return booking.renterId == userId || booking.vehicle.ownerId == userId
        }
        guard hits else { return nil }
        return "Finish or cancel your Pending, Approved, or Ongoing bookings first."
    }

    @MainActor
    func anonymizeDeletedUser(_ userId: String) async {
        for index in bookings.indices {
            if bookings[index].renterId == userId {
                bookings[index].renterName = "Deleted user"
                bookings[index].renterContact = ""
                try? await BookingService.update(bookings[index], fields: ["renterName", "renterContact"])
            }
            if bookings[index].ownerId == userId {
                bookings[index].ownerContact = nil
                try? await BookingService.update(bookings[index], fields: ["ownerContact"])
            }
        }
    }

    func renterCompletedTripCount(renterId: String?) -> Int {
        guard let renterId else { return 0 }
        return bookings.filter { $0.renterId == renterId && $0.status == .completed }.count
    }

    // Uses the renter's ratingSum/ratingCount, since an owner only sees their own bookings.
    func renterRatingSummary(renter: User?) -> (text: String, count: Int) {
        guard let renter, renter.ratingCount > 0 else { return ("New", 0) }
        return (String(format: "%.1f", renter.ratingSum / Double(renter.ratingCount)), renter.ratingCount)
    }

    func extraCost(for booking: Booking, extraDays: Int) -> Int {
        let days = max(extraDays, 1)
        return booking.vehicle.pricePerDay * days + (booking.addon ? booking.addonPrice * days : 0)
    }

    func beginExtend(bookingId: String) {
        guard let booking = booking(id: bookingId),
              booking.status == .approved || booking.status == .ongoing,
              booking.pendingExtension == nil else { return }
        extendBookingId = bookingId
        extendExtraDays = 1
        showExtendSheet = true
    }

    func requestExtension(vehicle: Vehicle) {
        guard let id = extendBookingId,
              let index = bookings.firstIndex(where: { $0.id == id }) else { return }
        let booking = bookings[index]
        guard booking.status == .approved || booking.status == .ongoing else { return }
        guard booking.pendingExtension == nil else {
            overlapAlertMessage = "You already have a pending extension request."
            return
        }
        let extra = min(max(extendExtraDays, 1), 7)
        guard let newEnd = Calendar.current.date(byAdding: .day, value: extra, to: booking.endDate) else { return }
        guard !hasOverlappingBooking(vehicleId: booking.vehicle.id, start: booking.endDate, end: newEnd) else {
            overlapAlertMessage = "Those extra days overlap another booking."
            return
        }
        guard !hasBlockedDates(vehicle: vehicle, start: booking.endDate, end: newEnd) else {
            overlapAlertMessage = "The owner blocked some of those dates. Pick fewer extra days."
            return
        }
        let extraKeys = occupiedDateKeys(from: booking.endDate, to: newEnd)
        isSaving = true
        Task { @MainActor in
            let free = (try? await BookingService.areDaysFree(vehicleId: booking.vehicle.id, dayKeys: extraKeys)) ?? false
            isSaving = false
            guard free else {
                overlapAlertMessage = "Those extra days overlap another booking."
                return
            }
            guard let index = bookings.firstIndex(where: { $0.id == id }) else { return }
            var list = bookings[index].rentalExtensions
            list.append(
                RentalExtension(
                    id: UUID().uuidString,
                    extraDays: extra,
                    extraCost: extraCost(for: booking, extraDays: extra),
                    status: .pending,
                    date: Date()
                )
            )
            bookings[index].extensions = list
            persist(id, ["extensions"])
            addNotification(
                "Extension request: +\(extra) day\(extra == 1 ? "" : "s") for \(booking.vehicle.name).",
                bookingId: id
            )
            showExtendSheet = false
            extendBookingId = nil
        }
    }

    func approveExtension(_ bookingId: String) {
        guard let index = bookings.firstIndex(where: { $0.id == bookingId }),
              let extIndex = bookings[index].rentalExtensions.firstIndex(where: { $0.status == .pending }) else { return }
        var updated = bookings[index]
        var list = updated.rentalExtensions
        let extra = list[extIndex].extraDays
        let cost = list[extIndex].extraCost
        list[extIndex].status = .approved
        updated.extensions = list
        let oldEnd = updated.endDate
        guard let newEnd = Calendar.current.date(byAdding: .day, value: extra, to: oldEnd) else { return }
        updated.endDate = newEnd
        updated.days += extra
        updated.totalPrice += cost
        let extraKeys = occupiedDateKeys(from: oldEnd, to: newEnd)
        let approved = updated

        isSaving = true
        Task { @MainActor in
            let updated = approved
            do {
                try await BookingService.reserveExtraDays(
                    updated,
                    dayKeys: extraKeys,
                    fields: ["extensions", "endDate", "days", "totalPrice"]
                )
            } catch {
                isSaving = false
                alertMessage = "Can't approve: \(error.localizedDescription)"
                return
            }
            isSaving = false
            if let index = bookings.firstIndex(where: { $0.id == bookingId }) {
                bookings[index] = updated
            }
            LocalNotificationService.shared.scheduleBookingReminders(for: updated)
            addNotification(
                "Your extension for \(updated.vehicle.name) was approved. New end date \(AppFormat.shortDate(newEnd)).",
                bookingId: bookingId
            )
        }
    }

    func declineExtension(_ bookingId: String) {
        guard let index = bookings.firstIndex(where: { $0.id == bookingId }),
              let extIndex = bookings[index].rentalExtensions.firstIndex(where: { $0.status == .pending }) else { return }
        var list = bookings[index].rentalExtensions
        list[extIndex].status = .declined
        bookings[index].extensions = list
        persist(bookingId, ["extensions"])
        addNotification(
            "Your extension request for \(bookings[index].vehicle.name) was declined.",
            bookingId: bookingId
        )
    }

    func rescheduleReminders(for bookingId: String) {
        guard let booking = booking(id: bookingId) else { return }
        LocalNotificationService.shared.scheduleBookingReminders(for: booking)
    }

    func syncScheduledReminders() {
        if !LocalNotificationService.shared.isEnabled {
            LocalNotificationService.shared.cancelAllBookingReminders()
            return
        }
        for booking in bookings where booking.status == .approved || booking.status == .ongoing {
            LocalNotificationService.shared.scheduleBookingReminders(for: booking)
        }
    }

    func saveOwnerRating(bookingId: String, renterRating: Int, comment: String) {
        guard let index = bookings.firstIndex(where: { $0.id == bookingId }) else { return }
        let alreadyRated = bookings[index].renterRating != nil
        bookings[index].renterRating = renterRating
        bookings[index].ratingComment = comment
        persist(bookingId, ["renterRating", "ratingComment"])
        if !alreadyRated, let renterId = bookings[index].renterId {
            addUserRating(uid: renterId, stars: renterRating)
        }
    }

    func markCashReceived(_ id: String) {
        guard let index = bookings.firstIndex(where: { $0.id == id }) else { return }
        bookings[index].paymentStatus = .paid
        persist(id, ["paymentStatus"])
        addNotification("Cash payment for \(bookings[index].vehicle.name) was marked received.", bookingId: id)
    }

    func markPaymentReceived(_ id: String) {
        guard let index = bookings.firstIndex(where: { $0.id == id }) else { return }
        bookings[index].paymentStatus = .paid
        persist(id, ["paymentStatus"])
        addNotification("Your payment for \(bookings[index].vehicle.name) was confirmed.", bookingId: id)
    }

    func beginRejectProof(_ id: String) {
        rejectProofBookingId = id
        showRejectProofSheet = true
    }

    func rejectPaymentProof(reason: PaymentRejectReason) {
        guard let id = rejectProofBookingId, let index = bookings.firstIndex(where: { $0.id == id }) else { return }
        bookings[index].paymentStatus = .rejected
        bookings[index].paymentRejectReason = reason.rawValue
        persist(id, ["paymentStatus", "paymentRejectReason"])
        addNotification(
            "Payment proof for \(bookings[index].vehicle.name) was rejected. Reason: \(reason.rawValue). You can upload again.",
            bookingId: id
        )
        rejectProofBookingId = nil
        showRejectProofSheet = false
    }

    func preparePaymentProof(bookingId: String) {
        proofBookingId = bookingId
        paymentReferenceDraft = booking(id: bookingId)?.paymentReference ?? ""
        paymentProofDraft = booking(id: bookingId)?.paymentProofFile
        paymentProofError = nil
    }

    private var proofBookingId: String?

    func savePaymentProofPhoto(_ image: UIImage) {
        uploadBookingPhoto(image, bookingId: proofBookingId) { [weak self] reference in
            self?.paymentProofDraft = reference
        }
    }

    func submitPaymentProof(bookingId: String) {
        paymentProofError = nil
        let reference = paymentReferenceDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard reference.count >= 6 else {
            paymentProofError = "Reference number must be at least 6 characters."
            return
        }
        guard let proof = paymentProofDraft else {
            paymentProofError = "Upload a payment screenshot."
            return
        }
        guard let index = bookings.firstIndex(where: { $0.id == bookingId }) else { return }
        bookings[index].paymentReference = reference
        bookings[index].paymentProofFile = proof
        bookings[index].paymentStatus = .proofSubmitted
        bookings[index].paymentRejectReason = nil
        persist(bookingId, ["paymentReference", "paymentProofFile", "paymentStatus", "paymentRejectReason"])
        addNotification(
            "Payment proof submitted for \(bookings[index].vehicle.name). Reference \(reference).",
            bookingId: bookingId
        )
    }

    func saveDeductionPhoto(_ image: UIImage) {
        uploadBookingPhoto(image, bookingId: deductionBookingId) { [weak self] reference in
            self?.draftDeductionPhoto = reference
        }
    }

    func addDeduction() {
        guard let id = deductionBookingId, let index = bookings.firstIndex(where: { $0.id == id }) else { return }
        let amount = Int(draftDeductionAmount) ?? 0
        let reason = draftDeductionReason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard amount > 0, !reason.isEmpty else { return }
        let current = bookings[index].depositDeductions
        guard current.reduce(0, { $0 + $1.amount }) + amount <= bookings[index].deposit else { return }
        var list = current
        list.append(
            DepositDeduction(
                id: UUID().uuidString,
                amount: amount,
                reason: reason,
                photoFile: draftDeductionPhoto
            )
        )
        bookings[index].deductions = list
        bookings[index].depositRefundAmount = max(bookings[index].deposit - list.reduce(0) { $0 + $1.amount }, 0)
        persist(id, ["deductions", "depositRefundAmount"])
        draftDeductionAmount = ""
        draftDeductionReason = ""
        draftDeductionPhoto = nil
    }

    func finishDeductions() {
        guard let id = deductionBookingId, let index = bookings.firstIndex(where: { $0.id == id }) else {
            showDeductionSheet = false
            return
        }
        let refund = bookings[index].depositRefund
        bookings[index].depositRefundAmount = refund
        persist(id, ["depositRefundAmount"])
        addNotification(
            "Deposit update for \(bookings[index].vehicle.name): refund \(AppFormat.peso(refund)).",
            bookingId: id
        )
        deductionBookingId = nil
        showDeductionSheet = false
    }
}
