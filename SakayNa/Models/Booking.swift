import Foundation

struct DepositDeduction: Identifiable, Hashable, Codable {
    let id: String
    var amount: Int
    var reason: String
    var photoFile: String?
}

struct RentalExtension: Identifiable, Hashable, Codable {
    let id: String
    var extraDays: Int
    var extraCost: Int
    var status: ExtensionStatus
    var date: Date
}

struct Booking: Identifiable, Hashable, Codable {
    var id: String
    let vehicle: Vehicle
    let startDate: Date
    var endDate: Date
    var days: Int
    let addon: Bool
    let addonPrice: Int
    var totalPrice: Int
    var status: BookingStatus
    var location: String
    let paymentMethod: PaymentMethod
    var renterName: String
    var renterId: String?
    var renterContact: String
    var ownerContact: String?
    var pickupTime: String?
    var messages: [ChatMessage]
    var vehicleRating: Int?
    var ownerRating: Int?
    var renterRating: Int?
    var ratingComment: String?
    var cancelReason: String? = nil
    var depositAmount: Int? = nil
    var depositReturned: Bool? = nil
    var lateFee: Int? = nil
    var pickupPhotos: [String: String]? = nil
    var returnPhotos: [String: String]? = nil
    var pickupNote: String? = nil
    var returnNote: String? = nil
    var pickupFuel: String? = nil
    var returnFuel: String? = nil
    var deductions: [DepositDeduction]? = nil
    var depositRefundAmount: Int? = nil
    var paymentStatus: PaymentStatus? = nil
    var paymentReference: String? = nil
    var paymentProofFile: String? = nil
    var paymentRejectReason: String? = nil
    var pickupPIN: String? = nil
    var pickupPINVerified: Bool? = nil
    var extensions: [RentalExtension]? = nil
    var ownerId: String = ""
    var pickupPINHash: String? = nil
    var renterLicenseRef: String? = nil

    var rentalExtensions: [RentalExtension] { extensions ?? [] }
    var pendingExtension: RentalExtension? {
        rentalExtensions.first { $0.status == .pending }
    }
    var approvedExtraDays: Int {
        rentalExtensions.filter { $0.status == .approved }.reduce(0) { $0 + $1.extraDays }
    }

    var deposit: Int { depositAmount ?? 0 }
    var lateReturnFee: Int { lateFee ?? 0 }
    var wasDepositReturned: Bool { depositReturned ?? false }
    var extraLateDays: Int {
        let perDay = Int((Double(vehicle.pricePerDay) * 1.2).rounded())
        guard perDay > 0 else { return 0 }
        return lateReturnFee / perDay
    }

    var photosAtPickup: [String: String] { pickupPhotos ?? [:] }
    var photosAtReturn: [String: String] { returnPhotos ?? [:] }
    var depositDeductions: [DepositDeduction] { deductions ?? [] }
    var deductionsTotal: Int { depositDeductions.reduce(0) { $0 + $1.amount } }
    var depositRefund: Int {
        if let depositRefundAmount { return depositRefundAmount }
        return max(deposit - deductionsTotal, 0)
    }
    var currentPaymentStatus: PaymentStatus { paymentStatus ?? .unpaid }
    var isPaid: Bool { currentPaymentStatus == .paid }
    var pinWasVerified: Bool { pickupPINVerified ?? false }

    var canCancel: Bool {
        status == .pending || status == .approved
    }

    var isApprovedOrLater: Bool {
        status == .approved || status == .ongoing || status == .completed
    }

    var renterHasRated: Bool {
        vehicleRating != nil && ownerRating != nil
    }

    var ownerHasRated: Bool {
        renterRating != nil
    }
}

// Stored in bookings/{id}; the id is the document id. vehicle is a snapshot of
// the listing at booking time. pickupPIN is never stored here: only its hash.
// The plain PIN lives in bookings/{id}/private/pin (renter only).
extension Booking {
    enum CodingKeys: String, CodingKey {
        case vehicle, vehicleId, ownerId, startDate, endDate, days, addon, addonPrice, totalPrice
        case status, location, paymentMethod, renterName, renterId, renterContact, ownerContact
        case pickupTime, messages, vehicleRating, ownerRating, renterRating, ratingComment
        case cancelReason, depositAmount, depositReturned, lateFee, pickupPhotos, returnPhotos
        case pickupNote, returnNote, pickupFuel, returnFuel, deductions, depositRefundAmount
        case paymentStatus, paymentReference, paymentProofFile, paymentRejectReason
        case pickupPINVerified, extensions, pickupPINHash, renterLicenseRef
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = ""
        vehicle = try c.decode(Vehicle.self, forKey: .vehicle)
        ownerId = try c.decodeIfPresent(String.self, forKey: .ownerId) ?? vehicle.ownerId
        startDate = try c.decodeIfPresent(Date.self, forKey: .startDate) ?? Date()
        endDate = try c.decodeIfPresent(Date.self, forKey: .endDate) ?? startDate
        days = try c.decodeIfPresent(Int.self, forKey: .days) ?? 1
        addon = try c.decodeIfPresent(Bool.self, forKey: .addon) ?? false
        addonPrice = try c.decodeIfPresent(Int.self, forKey: .addonPrice) ?? 0
        totalPrice = try c.decodeIfPresent(Int.self, forKey: .totalPrice) ?? 0
        status = try c.decodeIfPresent(BookingStatus.self, forKey: .status) ?? .pending
        location = try c.decodeIfPresent(String.self, forKey: .location) ?? ""
        paymentMethod = try c.decodeIfPresent(PaymentMethod.self, forKey: .paymentMethod) ?? .gcash
        renterName = try c.decodeIfPresent(String.self, forKey: .renterName) ?? ""
        renterId = try c.decodeIfPresent(String.self, forKey: .renterId)
        renterContact = try c.decodeIfPresent(String.self, forKey: .renterContact) ?? ""
        ownerContact = try c.decodeIfPresent(String.self, forKey: .ownerContact)
        pickupTime = try c.decodeIfPresent(String.self, forKey: .pickupTime)
        messages = try c.decodeIfPresent([ChatMessage].self, forKey: .messages) ?? []
        vehicleRating = try c.decodeIfPresent(Int.self, forKey: .vehicleRating)
        ownerRating = try c.decodeIfPresent(Int.self, forKey: .ownerRating)
        renterRating = try c.decodeIfPresent(Int.self, forKey: .renterRating)
        ratingComment = try c.decodeIfPresent(String.self, forKey: .ratingComment)
        cancelReason = try c.decodeIfPresent(String.self, forKey: .cancelReason)
        depositAmount = try c.decodeIfPresent(Int.self, forKey: .depositAmount)
        depositReturned = try c.decodeIfPresent(Bool.self, forKey: .depositReturned)
        lateFee = try c.decodeIfPresent(Int.self, forKey: .lateFee)
        pickupPhotos = try c.decodeIfPresent([String: String].self, forKey: .pickupPhotos)
        returnPhotos = try c.decodeIfPresent([String: String].self, forKey: .returnPhotos)
        pickupNote = try c.decodeIfPresent(String.self, forKey: .pickupNote)
        returnNote = try c.decodeIfPresent(String.self, forKey: .returnNote)
        pickupFuel = try c.decodeIfPresent(String.self, forKey: .pickupFuel)
        returnFuel = try c.decodeIfPresent(String.self, forKey: .returnFuel)
        deductions = try c.decodeIfPresent([DepositDeduction].self, forKey: .deductions)
        depositRefundAmount = try c.decodeIfPresent(Int.self, forKey: .depositRefundAmount)
        paymentStatus = try c.decodeIfPresent(PaymentStatus.self, forKey: .paymentStatus)
        paymentReference = try c.decodeIfPresent(String.self, forKey: .paymentReference)
        paymentProofFile = try c.decodeIfPresent(String.self, forKey: .paymentProofFile)
        paymentRejectReason = try c.decodeIfPresent(String.self, forKey: .paymentRejectReason)
        pickupPINVerified = try c.decodeIfPresent(Bool.self, forKey: .pickupPINVerified)
        extensions = try c.decodeIfPresent([RentalExtension].self, forKey: .extensions)
        pickupPINHash = try c.decodeIfPresent(String.self, forKey: .pickupPINHash)
        renterLicenseRef = try c.decodeIfPresent(String.self, forKey: .renterLicenseRef)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(vehicle, forKey: .vehicle)
        try c.encode(vehicle.id, forKey: .vehicleId)
        try c.encode(ownerId, forKey: .ownerId)
        try c.encode(startDate, forKey: .startDate)
        try c.encode(endDate, forKey: .endDate)
        try c.encode(days, forKey: .days)
        try c.encode(addon, forKey: .addon)
        try c.encode(addonPrice, forKey: .addonPrice)
        try c.encode(totalPrice, forKey: .totalPrice)
        try c.encode(status, forKey: .status)
        try c.encode(location, forKey: .location)
        try c.encode(paymentMethod, forKey: .paymentMethod)
        try c.encode(renterName, forKey: .renterName)
        try c.encodeIfPresent(renterId, forKey: .renterId)
        try c.encode(renterContact, forKey: .renterContact)
        try c.encodeIfPresent(ownerContact, forKey: .ownerContact)
        try c.encodeIfPresent(pickupTime, forKey: .pickupTime)
        try c.encode(messages, forKey: .messages)
        try c.encodeIfPresent(vehicleRating, forKey: .vehicleRating)
        try c.encodeIfPresent(ownerRating, forKey: .ownerRating)
        try c.encodeIfPresent(renterRating, forKey: .renterRating)
        try c.encodeIfPresent(ratingComment, forKey: .ratingComment)
        try c.encodeIfPresent(cancelReason, forKey: .cancelReason)
        try c.encodeIfPresent(depositAmount, forKey: .depositAmount)
        try c.encodeIfPresent(depositReturned, forKey: .depositReturned)
        try c.encodeIfPresent(lateFee, forKey: .lateFee)
        try c.encodeIfPresent(pickupPhotos, forKey: .pickupPhotos)
        try c.encodeIfPresent(returnPhotos, forKey: .returnPhotos)
        try c.encodeIfPresent(pickupNote, forKey: .pickupNote)
        try c.encodeIfPresent(returnNote, forKey: .returnNote)
        try c.encodeIfPresent(pickupFuel, forKey: .pickupFuel)
        try c.encodeIfPresent(returnFuel, forKey: .returnFuel)
        try c.encodeIfPresent(deductions, forKey: .deductions)
        try c.encodeIfPresent(depositRefundAmount, forKey: .depositRefundAmount)
        try c.encodeIfPresent(paymentStatus, forKey: .paymentStatus)
        try c.encodeIfPresent(paymentReference, forKey: .paymentReference)
        try c.encodeIfPresent(paymentProofFile, forKey: .paymentProofFile)
        try c.encodeIfPresent(paymentRejectReason, forKey: .paymentRejectReason)
        try c.encodeIfPresent(pickupPINVerified, forKey: .pickupPINVerified)
        try c.encodeIfPresent(extensions, forKey: .extensions)
        try c.encodeIfPresent(pickupPINHash, forKey: .pickupPINHash)
        try c.encodeIfPresent(renterLicenseRef, forKey: .renterLicenseRef)
    }
}
