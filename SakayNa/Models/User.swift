import Foundation

struct User: Hashable, Codable {
    var id: String
    var name: String
    var email: String
    var phone: String
    var password: String
    var avatarColorHex: String
    var role: UserRole
    var gcashNumber: String
    var mayaNumber: String
    var bankAccount: String
    var qrPhEnabled: Bool
    var licenseFileName: String? = nil
    var qrFileName: String? = nil
    var isVerified: Bool? = nil
    var idFileName: String? = nil
    var termsAcceptedAt: Date? = nil
    var favorites: [String] = []
    var ratingSum: Double = 0
    var ratingCount: Int = 0

    var isVerifiedOwner: Bool { (isVerified ?? false) && role == .owner }
    var hasLicensePhoto: Bool {
        guard let licenseFileName, !licenseFileName.isEmpty else { return false }
        return true
    }

    var firstName: String {
        name.split(separator: " ").first.map(String.init) ?? "User"
    }

    var initial: String {
        String(name.prefix(1)).uppercased()
    }

    // Placeholder while nobody is signed in.
    static let empty = User(
        id: "user-empty",
        name: "",
        email: "",
        phone: "",
        password: "",
        avatarColorHex: "#4CAF50",
        role: .renter,
        gcashNumber: "",
        mayaNumber: "",
        bankAccount: "",
        qrPhEnabled: false
    )

    static let avatarPresets = ["#4CAF50", "#2196F3", "#FF9800", "#E91E63"]
}

// The password never goes to Firestore and the id is the document id (users/{uid}).
// The photo fields hold PhotoService references. Favorites are only written with
// arrayUnion/arrayRemove (UserService.setFavorite), and the rating counters only
// with increments (BookingService.addUserRating), so encode() leaves them out.
extension User {
    enum CodingKeys: String, CodingKey {
        case name, email, phone, avatarColorHex, role
        case gcashNumber, mayaNumber, bankAccount, qrPhEnabled
        case isVerified, termsAcceptedAt, favorites, ratingSum, ratingCount
        case licenseFileName = "licenseRef"
        case qrFileName = "qrRef"
        case idFileName = "idRef"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = ""
        password = ""
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        email = try c.decodeIfPresent(String.self, forKey: .email) ?? ""
        phone = try c.decodeIfPresent(String.self, forKey: .phone) ?? ""
        avatarColorHex = try c.decodeIfPresent(String.self, forKey: .avatarColorHex) ?? "#4CAF50"
        role = try c.decodeIfPresent(UserRole.self, forKey: .role) ?? .renter
        gcashNumber = try c.decodeIfPresent(String.self, forKey: .gcashNumber) ?? ""
        mayaNumber = try c.decodeIfPresent(String.self, forKey: .mayaNumber) ?? ""
        bankAccount = try c.decodeIfPresent(String.self, forKey: .bankAccount) ?? ""
        qrPhEnabled = try c.decodeIfPresent(Bool.self, forKey: .qrPhEnabled) ?? false
        licenseFileName = try c.decodeIfPresent(String.self, forKey: .licenseFileName)
        qrFileName = try c.decodeIfPresent(String.self, forKey: .qrFileName)
        isVerified = try c.decodeIfPresent(Bool.self, forKey: .isVerified)
        idFileName = try c.decodeIfPresent(String.self, forKey: .idFileName)
        termsAcceptedAt = try c.decodeIfPresent(Date.self, forKey: .termsAcceptedAt)
        favorites = try c.decodeIfPresent([String].self, forKey: .favorites) ?? []
        ratingSum = try c.decodeIfPresent(Double.self, forKey: .ratingSum) ?? 0
        ratingCount = try c.decodeIfPresent(Int.self, forKey: .ratingCount) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(email, forKey: .email)
        try c.encode(phone, forKey: .phone)
        try c.encode(avatarColorHex, forKey: .avatarColorHex)
        try c.encode(role, forKey: .role)
        try c.encode(gcashNumber, forKey: .gcashNumber)
        try c.encode(mayaNumber, forKey: .mayaNumber)
        try c.encode(bankAccount, forKey: .bankAccount)
        try c.encode(qrPhEnabled, forKey: .qrPhEnabled)
        try c.encodeIfPresent(licenseFileName, forKey: .licenseFileName)
        try c.encodeIfPresent(qrFileName, forKey: .qrFileName)
        try c.encodeIfPresent(isVerified, forKey: .isVerified)
        try c.encodeIfPresent(idFileName, forKey: .idFileName)
        try c.encodeIfPresent(termsAcceptedAt, forKey: .termsAcceptedAt)
    }
}
