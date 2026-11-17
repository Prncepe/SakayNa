import Foundation

struct ChatMessage: Identifiable, Hashable, Codable {
    let id: String
    let text: String
    let sender: UserRole
    let timestamp: Date
}
