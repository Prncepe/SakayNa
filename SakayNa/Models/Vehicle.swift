import Foundation

// Stored in vehicles/{vehicleId}/reviews/{id}. The id is the document id.
struct VehicleReview: Identifiable, Hashable, Codable {
    var id: String
    var renterId: String = ""
    var renterName: String
    var rating: Int
    var comment: String
    var date: Date

    enum CodingKeys: String, CodingKey {
        case renterId, renterName, comment, date
        case rating = "stars"
    }

    init(id: String, renterId: String = "", renterName: String, rating: Int, comment: String, date: Date) {
        self.id = id
        self.renterId = renterId
        self.renterName = renterName
        self.rating = rating
        self.comment = comment
        self.date = date
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = ""
        renterId = try c.decodeIfPresent(String.self, forKey: .renterId) ?? ""
        renterName = try c.decodeIfPresent(String.self, forKey: .renterName) ?? "Renter"
        rating = try c.decodeIfPresent(Int.self, forKey: .rating) ?? 0
        comment = try c.decodeIfPresent(String.self, forKey: .comment) ?? ""
        date = try c.decodeIfPresent(Date.self, forKey: .date) ?? Date()
    }
}

struct VehicleSpecs: Hashable, Codable {
    var engine: String
    var power: String
    var torque: String
    var fuelType: String
    var transmission: String
    var fuelTank: String
    var brakes: String?
    var topSpeed: String?
}

// Stored in vehicles/{id}. photoFiles = "photoRefs" and orcrFileName = "orcrRef"
// hold PhotoService references. rating/reviewCount are computed from
// ratingSum/ratingCount; reviews come from the reviews subcollection.
struct Vehicle: Identifiable, Hashable, Codable {
    var id: String
    var ownerId: String
    var name: String
    var brand: String
    var type: VehicleType
    var imageName: String
    var customImageFile: String?
    var description: String
    var pricePerDay: Int
    var location: String
    var seats: Int
    var ratingSum: Double
    var ratingCount: Int
    var specs: VehicleSpecs
    var reviews: [VehicleReview]
    var isActive: Bool
    var blockedDateKeys: [String]
    var orcrFileName: String?
    var photoFiles: [String]? = nil

    var galleryFiles: [String] {
        if let photoFiles, !photoFiles.isEmpty { return Array(photoFiles.prefix(5)) }
        if let customImageFile, !customImageFile.isEmpty { return [customImageFile] }
        return []
    }

    var coverFile: String? { galleryFiles.first }

    var rating: String {
        ratingCount == 0 ? "0.0" : String(format: "%.1f", ratingSum / Double(ratingCount))
    }

    var reviewCount: Int { ratingCount }

    var securityDeposit: Int {
        type == .car ? 1500 : 500
    }

    var hasRegistration: Bool {
        if let name = orcrFileName, !name.isEmpty { return true }
        return false
    }

    var riderLabel: String {
        type == .motorcycle ? "\(seats) riders" : "\(seats) seats"
    }

    var addonLabel: String {
        type == .car ? "Driver (₱500/day)" : "Helmet (₱50/day)"
    }

    var addonPricePerDay: Int {
        type == .car ? 500 : 50
    }

    var specTiles: [(String, String)] {
        var tiles: [(String, String)] = []
        addTile(&tiles, "Engine", specs.engine)
        addTile(&tiles, "Power", specs.power)
        addTile(&tiles, "Fuel Type", specs.fuelType)
        addTile(&tiles, "Transmission", specs.transmission)
        addTile(&tiles, "Fuel Tank", specs.fuelTank)
        if type == .motorcycle {
            addTile(&tiles, "Brakes", specs.brakes ?? "")
        } else {
            addTile(&tiles, "Seats", "\(seats)")
        }
        return tiles
    }

    var extraSpecTiles: [(String, String)] {
        var tiles: [(String, String)] = []
        addTile(&tiles, "Torque", specs.torque)
        addTile(&tiles, "Top Speed", specs.topSpeed ?? "")
        return tiles
    }

    enum CodingKeys: String, CodingKey {
        case id, ownerId, name, brand, type, imageName, customImageFile, description
        case pricePerDay, location, place, seats, rating, reviewCount, ratingsCount
        case photoURL, photoFileName, engine, fuel, transmission, topSpeed, capacity, brakes
        case specs, reviews, isActive, blockedDateKeys, ratingSum, ratingCount
        case orcrFileName = "orcrRef"
        case photoFiles = "photoRefs"
    }

    init(
        id: String,
        ownerId: String,
        name: String,
        brand: String,
        type: VehicleType,
        imageName: String,
        customImageFile: String? = nil,
        description: String,
        pricePerDay: Int,
        location: String,
        seats: Int,
        rating: String,
        reviewCount: Int,
        specs: VehicleSpecs,
        reviews: [VehicleReview] = [],
        isActive: Bool,
        blockedDateKeys: [String] = [],
        orcrFileName: String? = nil,
        photoFiles: [String]? = nil
    ) {
        self.id = id
        self.ownerId = ownerId
        self.name = name
        self.brand = brand
        self.type = type
        self.imageName = imageName
        self.customImageFile = customImageFile
        self.description = description
        self.pricePerDay = pricePerDay
        self.location = location
        self.seats = seats
        self.ratingSum = (Double(rating) ?? 0) * Double(reviewCount)
        self.ratingCount = reviewCount
        self.specs = specs
        self.reviews = reviews
        self.isActive = isActive
        self.blockedDateKeys = blockedDateKeys
        self.orcrFileName = orcrFileName
        self.photoFiles = photoFiles
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
        ownerId = try container.decodeIfPresent(String.self, forKey: .ownerId) ?? ""
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Vehicle"
        type = try container.decodeIfPresent(VehicleType.self, forKey: .type) ?? .motorcycle
        pricePerDay = try container.decodeIfPresent(Int.self, forKey: .pricePerDay) ?? 0
        location = try container.decodeIfPresent(String.self, forKey: .location)
            ?? container.decodeIfPresent(String.self, forKey: .place)
            ?? ""
        customImageFile = try container.decodeIfPresent(String.self, forKey: .customImageFile)
            ?? container.decodeIfPresent(String.self, forKey: .photoFileName)
        imageName = try container.decodeIfPresent(String.self, forKey: .imageName) ?? Vehicle.legacyImageName(for: id)
        brand = try container.decodeIfPresent(String.self, forKey: .brand) ?? (name.split(separator: " ").first.map(String.init) ?? name)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        if let value = try container.decodeIfPresent(Int.self, forKey: .seats) {
            seats = value
        } else if let capacity = try container.decodeIfPresent(String.self, forKey: .capacity),
                  let parsed = Int(capacity.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
            seats = type == .car ? max(parsed, 1) : 2
        } else {
            seats = type == .car ? 5 : 2
        }
        if let count = try container.decodeIfPresent(Int.self, forKey: .ratingCount) {
            ratingCount = count
            ratingSum = try container.decodeIfPresent(Double.self, forKey: .ratingSum) ?? 0
        } else {
            let oldCount = try container.decodeIfPresent(Int.self, forKey: .reviewCount)
                ?? container.decodeIfPresent(Int.self, forKey: .ratingsCount)
                ?? 0
            var oldAverage = 0.0
            if let value = try? container.decode(String.self, forKey: .rating) {
                oldAverage = Double(value) ?? 0
            } else if let value = try? container.decode(Double.self, forKey: .rating) {
                oldAverage = value
            }
            ratingCount = oldCount
            ratingSum = oldAverage * Double(oldCount)
        }
        if let nested = try container.decodeIfPresent(VehicleSpecs.self, forKey: .specs) {
            specs = nested
        } else {
            specs = VehicleSpecs(
                engine: try container.decodeIfPresent(String.self, forKey: .engine) ?? "",
                power: "",
                torque: "",
                fuelType: try container.decodeIfPresent(String.self, forKey: .fuel) ?? "",
                transmission: try container.decodeIfPresent(String.self, forKey: .transmission) ?? "",
                fuelTank: try container.decodeIfPresent(String.self, forKey: .capacity) ?? "",
                brakes: try container.decodeIfPresent(String.self, forKey: .brakes),
                topSpeed: try container.decodeIfPresent(String.self, forKey: .topSpeed)
            )
        }
        reviews = try container.decodeIfPresent([VehicleReview].self, forKey: .reviews) ?? []
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        blockedDateKeys = try container.decodeIfPresent([String].self, forKey: .blockedDateKeys) ?? []
        orcrFileName = try container.decodeIfPresent(String.self, forKey: .orcrFileName)
        photoFiles = try container.decodeIfPresent([String].self, forKey: .photoFiles)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(ownerId, forKey: .ownerId)
        try container.encode(name, forKey: .name)
        try container.encode(brand, forKey: .brand)
        try container.encode(type, forKey: .type)
        try container.encode(imageName, forKey: .imageName)
        try container.encode(description, forKey: .description)
        try container.encode(pricePerDay, forKey: .pricePerDay)
        try container.encode(location, forKey: .location)
        try container.encode(seats, forKey: .seats)
        try container.encode(ratingSum, forKey: .ratingSum)
        try container.encode(ratingCount, forKey: .ratingCount)
        try container.encode(specs, forKey: .specs)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(blockedDateKeys, forKey: .blockedDateKeys)
        try container.encodeIfPresent(orcrFileName, forKey: .orcrFileName)
        try container.encodeIfPresent(photoFiles, forKey: .photoFiles)
    }

    static func dateKey(for date: Date) -> String {
        dateKeyFormatter.string(from: Calendar.current.startOfDay(for: date))
    }

    static func date(fromKey key: String) -> Date? {
        dateKeyFormatter.date(from: key)
    }

    private static let dateKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static func legacyImageName(for id: String) -> String {
        switch id {
        case "0": return "click"
        case "1": return "nmax"
        case "2": return "vios"
        case "3": return "brv"
        default: return ""
        }
    }

    private func addTile(_ tiles: inout [(String, String)], _ label: String, _ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        tiles.append((label, trimmed))
    }
}
