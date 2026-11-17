import Foundation

// Stored in users/{uid}/notifications/{id}. The id is the document id.
struct AppNotification: Identifiable, Hashable, Codable {
    var id: String
    let message: String
    var isRead: Bool
    let timestamp: Date
    var bookingId: String?
    var conversationId: String?
    var createdBy: String = ""

    enum CodingKeys: String, CodingKey {
        case type, title, message, isRead, bookingId, conversationId, createdBy
        case timestamp = "createdAt"
    }

    init(
        id: String,
        message: String,
        isRead: Bool,
        timestamp: Date,
        bookingId: String? = nil,
        conversationId: String? = nil,
        createdBy: String = ""
    ) {
        self.id = id
        self.message = message
        self.isRead = isRead
        self.timestamp = timestamp
        self.bookingId = bookingId
        self.conversationId = conversationId
        self.createdBy = createdBy
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = ""
        message = try c.decodeIfPresent(String.self, forKey: .message) ?? ""
        isRead = try c.decodeIfPresent(Bool.self, forKey: .isRead) ?? false
        timestamp = try c.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date.distantPast
        bookingId = try c.decodeIfPresent(String.self, forKey: .bookingId)
        conversationId = try c.decodeIfPresent(String.self, forKey: .conversationId)
        createdBy = try c.decodeIfPresent(String.self, forKey: .createdBy) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(conversationId == nil ? "booking" : "message", forKey: .type)
        try c.encode(bannerTitle, forKey: .title)
        try c.encode(message, forKey: .message)
        try c.encode(isRead, forKey: .isRead)
        try c.encode(timestamp, forKey: .timestamp)
        try c.encodeIfPresent(bookingId, forKey: .bookingId)
        try c.encodeIfPresent(conversationId, forKey: .conversationId)
        try c.encode(createdBy, forKey: .createdBy)
    }

    var bannerTitle: String {
        if conversationId != nil { return "New Message" }
        let text = message.lowercased()
        if text.contains("approved") { return "Booking Approved" }
        if text.contains("cancel") { return "Booking Cancelled" }
        if text.contains("request") { return "New Booking" }
        if text.contains("ended") || text.contains("rate") { return "Trip Complete" }
        if text.contains("pickup") || text.contains("ongoing") { return "Pickup Confirmed" }
        return "SakayNa"
    }

    var bannerSymbol: String {
        if conversationId != nil { return "ellipsis.message.fill" }
        let text = message.lowercased()
        if text.contains("cancel") { return "xmark.circle.fill" }
        if text.contains("approved") { return "checkmark.circle.fill" }
        if text.contains("rate") { return "star.fill" }
        if text.contains("message") { return "ellipsis.message.fill" }
        return "bell.fill"
    }
}
