import Foundation

enum VehicleType: String, Hashable, CaseIterable, Codable {
    case motorcycle = "Motorcycle"
    case car = "Car"
}

enum VehicleSort: String, CaseIterable, Hashable {
    case recommended = "Recommended"
    case priceLow = "Price low to high"
    case priceHigh = "Price high to low"
    case highestRated = "Highest rated"
}

enum OwnerCancelReason: String, CaseIterable, Hashable {
    case scheduleConflict = "Schedule conflict"
    case vehicleUnavailable = "Vehicle unavailable"
    case renterRequested = "Renter requested"
    case other = "Other"
}

enum ReportReason: String, CaseIterable, Hashable {
    case inappropriate = "Inappropriate messages"
    case spam = "Spam"
    case harassment = "Harassment"
    case other = "Other"
}

enum CityFilter: String, CaseIterable, Hashable {
    case all = "All cities"
    case lucena = "Lucena"
    case lipa = "Lipa"
    case batangasCity = "Batangas City"
    case manila = "Manila"
}

enum VehicleFilter: String, CaseIterable, Hashable {
    case all = "All"
    case motorcycle = "Motorcycle"
    case car = "Car"

    var vehicleType: VehicleType? {
        switch self {
        case .all: return nil
        case .motorcycle: return .motorcycle
        case .car: return .car
        }
    }
}

enum BookingStatus: String, Hashable, Codable {
    case pending = "Pending"
    case approved = "Approved"
    case upcoming = "Upcoming"
    case ongoing = "Ongoing"
    case completed = "Completed"
    case declined = "Declined"
    case cancelled = "Cancelled"

    var badgeLabel: String {
        switch self {
        case .pending: return "Pending"
        case .approved: return "Approved"
        case .upcoming: return "Upcoming"
        case .ongoing: return "Ongoing"
        case .completed: return "Completed"
        case .declined: return "Declined"
        case .cancelled: return "Cancelled"
        }
    }
}

enum PaymentMethod: String, CaseIterable, Hashable, Codable {
    case gcash = "GCash"
    case maya = "Maya"
    case bankTransfer = "Bank Transfer"
    case qrPh = "QR Ph"
    case cash = "Cash"

    var detail: String {
        switch self {
        case .gcash: return "Pay securely with GCash"
        case .maya: return "Pay securely with Maya"
        case .bankTransfer: return "Transfer to the host's bank account"
        case .qrPh: return "Scan a QR Ph code to pay"
        case .cash: return "Pay in cash at pickup"
        }
    }

    var usesScanDetails: Bool {
        self != .cash
    }
}

enum UserRole: String, Codable {
    case renter
    case owner
}

enum BookingListTab: String, CaseIterable, Hashable {
    case upcoming = "Upcoming"
    case ongoing = "Ongoing"
    case completed = "Completed"
}

enum MainTab: Hashable {
    case home
    case bookings
    case messages
    case profile
}

enum RequestFilter: String, CaseIterable, Hashable {
    case pending = "Pending"
    case approved = "Approved"
    case ongoing = "Ongoing"
    case completed = "Completed"

    var matchingStatuses: [BookingStatus] {
        switch self {
        case .pending: return [.pending]
        case .approved: return [.approved]
        case .ongoing: return [.ongoing]
        case .completed: return [.completed, .declined, .cancelled]
        }
    }
}

enum ConditionAction {
    case pickup
    case returnVehicle
}

enum ConditionSide: String, CaseIterable, Hashable, Codable {
    case front = "Front"
    case back = "Back"
    case left = "Left"
    case right = "Right"
}

enum FuelLevel: String, CaseIterable, Hashable, Codable {
    case full = "Full"
    case threeQuarters = "¾"
    case half = "Half"
    case quarter = "¼"
    case empty = "Empty"
}

enum ExtensionStatus: String, Hashable, Codable {
    case pending = "Pending"
    case approved = "Approved"
    case declined = "Declined"
}

enum PaymentStatus: String, Hashable, Codable {
    case unpaid = "Unpaid"
    case proofSubmitted = "Proof Submitted"
    case paid = "Paid"
    case rejected = "Rejected"
}

enum PaymentRejectReason: String, CaseIterable, Hashable {
    case wrongAmount = "Wrong amount"
    case unclearPhoto = "Unclear screenshot"
    case wrongReference = "Wrong reference"
    case other = "Other"
}

enum AppRoute: Hashable {
    case allVehicles
    case vehicleDetail(String)
    case booking
    case payment
    case confirmation
    case editProfile
    case paymentMethods
    case helpSupport
    case addVehicle
    case tripTracking(String)
    case chat(String)
    case rateTrip(String)
    case licenseUpload
    case notificationSettings
    case termsAndConditions
    case privacyPolicy
    case savedVehicles
    case receipt(String)
    case about
    case verifyAccount
}

enum AuthScreen {
    case splash
    case login
    case signup
}
