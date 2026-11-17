import Foundation

// Stored in conversations/{id}/messages/{id}. The id is the document id.
struct Message: Identifiable, Hashable, Codable {
    var id: String
    var senderId: String
    var text: String
    var date: Date
    var isRead: Bool = true

    enum CodingKeys: String, CodingKey {
        case senderId, text, date
    }

    init(id: String, senderId: String, text: String, date: Date, isRead: Bool = true) {
        self.id = id
        self.senderId = senderId
        self.text = text
        self.date = date
        self.isRead = isRead
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = ""
        senderId = try c.decodeIfPresent(String.self, forKey: .senderId) ?? ""
        text = try c.decodeIfPresent(String.self, forKey: .text) ?? ""
        date = try c.decodeIfPresent(Date.self, forKey: .date) ?? Date()
    }
}

// Stored in conversations/{id}. The id is "renterId_ownerId_vehicleId" so both
// phones find the same chat. messages is only filled for the open chat; the
// inbox uses lastMessageText and the unread map instead.
struct Conversation: Identifiable, Hashable, Codable {
    var id: String
    var renterId: String
    var ownerId: String
    var vehicleId: String
    var bookingId: String?
    var messages: [Message] = []
    var lastUpdated: Date
    var lastMessageText: String = ""
    var lastSenderId: String = ""
    var unread: [String: Int] = [:]
    var blockedBy: [String] = []

    enum CodingKeys: String, CodingKey {
        case participantIds, renterId, ownerId, vehicleId, bookingId
        case lastUpdated, lastMessageText = "lastMessage", lastSenderId, unread, blockedBy
    }

    init(id: String, renterId: String, ownerId: String, vehicleId: String, bookingId: String?, lastUpdated: Date) {
        self.id = id
        self.renterId = renterId
        self.ownerId = ownerId
        self.vehicleId = vehicleId
        self.bookingId = bookingId
        self.lastUpdated = lastUpdated
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = ""
        renterId = try c.decodeIfPresent(String.self, forKey: .renterId) ?? ""
        ownerId = try c.decodeIfPresent(String.self, forKey: .ownerId) ?? ""
        vehicleId = try c.decodeIfPresent(String.self, forKey: .vehicleId) ?? ""
        bookingId = try c.decodeIfPresent(String.self, forKey: .bookingId)
        lastUpdated = try c.decodeIfPresent(Date.self, forKey: .lastUpdated) ?? Date.distantPast
        lastMessageText = try c.decodeIfPresent(String.self, forKey: .lastMessageText) ?? ""
        lastSenderId = try c.decodeIfPresent(String.self, forKey: .lastSenderId) ?? ""
        unread = try c.decodeIfPresent([String: Int].self, forKey: .unread) ?? [:]
        blockedBy = try c.decodeIfPresent([String].self, forKey: .blockedBy) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode([renterId, ownerId], forKey: .participantIds)
        try c.encode(renterId, forKey: .renterId)
        try c.encode(ownerId, forKey: .ownerId)
        try c.encode(vehicleId, forKey: .vehicleId)
        try c.encodeIfPresent(bookingId, forKey: .bookingId)
        try c.encode(lastUpdated, forKey: .lastUpdated)
        try c.encode(lastMessageText, forKey: .lastMessageText)
        try c.encode(lastSenderId, forKey: .lastSenderId)
        try c.encode(unread, forKey: .unread)
        try c.encode(blockedBy, forKey: .blockedBy)
    }

    static func makeId(renterId: String, ownerId: String, vehicleId: String) -> String {
        "\(renterId)_\(ownerId)_\(vehicleId)"
    }

    var lastMessage: Message? {
        if let last = messages.last { return last }
        guard !lastMessageText.isEmpty else { return nil }
        return Message(id: "last", senderId: lastSenderId, text: lastMessageText, date: lastUpdated)
    }

    func otherUserId(than userId: String) -> String {
        userId == renterId ? ownerId : renterId
    }

    func unreadCount(for userId: String) -> Int {
        unread[userId] ?? 0
    }
}
