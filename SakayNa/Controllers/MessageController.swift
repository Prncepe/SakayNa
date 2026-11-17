import Foundation
import Combine
import FirebaseFirestore

final class MessageController: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var chatDraft = ""
    @Published var alertMessage: String?
    @Published var isLoading = false
    @Published var isLoadingChat = false

    private var uid: String?
    private var inboxListener: ListenerRegistration?
    private var messagesListener: ListenerRegistration?
    private var openConversationId: String?
    private var openMessages: [Message] = []
    // Chats started on this phone that the server hasn't confirmed yet.
    private var pendingIds = Set<String>()
    private var messagesListenerFailed = false

    // MARK: - Listeners

    func start(uid: String) {
        stop()
        self.uid = uid
        isLoading = true
        inboxListener = ChatService.listenToInbox(uid: uid) { [weak self] list in
            guard let self else { return }
            isLoading = false
            let serverIds = Set(list.map(\.id))
            pendingIds.subtract(serverIds)
            let pending = conversations.filter { self.pendingIds.contains($0.id) }
            conversations = pending + list.map { conversation in
                var copy = conversation
                if copy.id == self.openConversationId {
                    copy.messages = self.openMessages
                }
                return copy
            }
            // The open chat's listener failed because the chat wasn't on the
            // server yet; now that it is, listen again.
            if let openId = openConversationId, messagesListenerFailed, serverIds.contains(openId) {
                openChat(openId, force: true)
            }
        } onError: { [weak self] error in
            self?.isLoading = false
            self?.alertMessage = "Couldn't load messages. \(error.localizedDescription)"
        }
    }

    func stop() {
        inboxListener?.remove()
        messagesListener?.remove()
        inboxListener = nil
        messagesListener = nil
        uid = nil
        conversations = []
        openConversationId = nil
        openMessages = []
        pendingIds = []
        chatDraft = ""
        isLoading = false
        isLoadingChat = false
    }

    // Called by ChatView so only the open chat streams its messages.
    func openChat(_ conversationId: String, force: Bool = false) {
        guard force || openConversationId != conversationId else { return }
        messagesListener?.remove()
        messagesListenerFailed = false
        openConversationId = conversationId
        openMessages = []
        isLoadingChat = !pendingIds.contains(conversationId)
        messagesListener = ChatService.listenToMessages(conversationId: conversationId) { [weak self] list in
            guard let self, openConversationId == conversationId else { return }
            isLoadingChat = false
            openMessages = list
            if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
                conversations[index].messages = list
            }
        } onError: { [weak self] error in
            guard let self, openConversationId == conversationId else { return }
            isLoadingChat = false
            messagesListenerFailed = true
            // A brand-new chat may not exist on the server yet, so a permission
            // error here just means "no messages yet".
            if !pendingIds.contains(conversationId) {
                alertMessage = "Couldn't load this chat. \(error.localizedDescription)"
            }
        }
    }

    func closeChat(_ conversationId: String) {
        guard openConversationId == conversationId else { return }
        messagesListener?.remove()
        messagesListener = nil
        openConversationId = nil
        openMessages = []
        isLoadingChat = false
    }

    // MARK: - Inbox

    func conversation(id: String) -> Conversation? {
        conversations.first { $0.id == id }
    }

    func inbox(for userId: String) -> [Conversation] {
        conversations
            .filter { conversation in
                guard conversation.renterId == userId || conversation.ownerId == userId else { return false }
                return !conversation.blockedBy.contains(userId)
            }
            .sorted { $0.lastUpdated > $1.lastUpdated }
    }

    func isBlocked(_ userId: String, by blockerId: String) -> Bool {
        conversations.contains { conversation in
            conversation.blockedBy.contains(blockerId)
                && (conversation.renterId == userId || conversation.ownerId == userId)
        }
    }

    func canMessage(from senderId: String, to otherId: String) -> Bool {
        !isBlocked(otherId, by: senderId) && !isBlocked(senderId, by: otherId)
    }

    func unreadCount(for userId: String) -> Int {
        inbox(for: userId).reduce(0) { $0 + $1.unreadCount(for: userId) }
    }

    // MARK: - Report and block

    func reportUser(reporterId: String, reportedUserId: String, reason: ReportReason, conversationId: String) {
        Task { @MainActor in
            do {
                try await ChatService.report(
                    reporterId: reporterId,
                    reportedId: reportedUserId,
                    reason: reason.rawValue,
                    conversationId: conversationId
                )
            } catch {
                alertMessage = "Couldn't send the report. \(error.localizedDescription)"
            }
        }
    }

    // Blocking adds the blocker to blockedBy on every chat with that user.
    // While blockedBy isn't empty, the rules reject new messages.
    func blockUser(blockerId: String, blockedUserId: String) {
        setBlocked(blockerId: blockerId, otherUserId: blockedUserId, isBlocked: true)
    }

    func unblockUser(blockerId: String, blockedUserId: String) {
        setBlocked(blockerId: blockerId, otherUserId: blockedUserId, isBlocked: false)
    }

    private func setBlocked(blockerId: String, otherUserId: String, isBlocked: Bool) {
        let ids = conversations
            .filter { $0.renterId == otherUserId || $0.ownerId == otherUserId }
            .map(\.id)
        for index in conversations.indices where ids.contains(conversations[index].id) {
            if isBlocked {
                if !conversations[index].blockedBy.contains(blockerId) {
                    conversations[index].blockedBy.append(blockerId)
                }
            } else {
                conversations[index].blockedBy.removeAll { $0 == blockerId }
            }
        }
        Task { @MainActor in
            do {
                for id in ids {
                    try await ChatService.setBlocked(conversationId: id, uid: blockerId, isBlocked: isBlocked)
                }
            } catch {
                alertMessage = "Couldn't update the block. \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Start or find a chat

    @discardableResult
    func startOrFind(
        renterId: String,
        ownerId: String,
        vehicleId: String,
        bookingId: String? = nil
    ) -> Conversation {
        let id = Conversation.makeId(renterId: renterId, ownerId: ownerId, vehicleId: vehicleId)
        if let index = conversations.firstIndex(where: { $0.id == id }) {
            if let bookingId, conversations[index].bookingId == nil {
                conversations[index].bookingId = bookingId
                let updated = conversations[index]
                Task { try? await ChatService.createIfNeeded(updated) }
            }
            return conversations[index]
        }

        let created = Conversation(
            id: id,
            renterId: renterId,
            ownerId: ownerId,
            vehicleId: vehicleId,
            bookingId: bookingId,
            lastUpdated: Date()
        )
        conversations.insert(created, at: 0)
        pendingIds.insert(id)
        Task { @MainActor in
            do {
                try await ChatService.createIfNeeded(created)
            } catch {
                pendingIds.remove(id)
                conversations.removeAll { $0.id == id }
                alertMessage = "Couldn't start the chat. \(error.localizedDescription)"
            }
        }
        return created
    }

    func conversation(for booking: Booking) -> Conversation {
        startOrFind(
            renterId: booking.renterId ?? "",
            ownerId: booking.ownerId.isEmpty ? booking.vehicle.ownerId : booking.ownerId,
            vehicleId: booking.vehicle.id,
            bookingId: booking.id
        )
    }

    // MARK: - Send and read

    @discardableResult
    func send(conversationId: String, senderId: String, text: String? = nil) -> Bool {
        let body = (text ?? chatDraft).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty,
              let index = conversations.firstIndex(where: { $0.id == conversationId }) else { return false }
        let conversation = conversations[index]
        let otherId = conversation.otherUserId(than: senderId)
        guard canMessage(from: senderId, to: otherId) else { return false }
        let message = Message(id: UUID().uuidString, senderId: senderId, text: body, date: Date())
        conversations[index].lastMessageText = body
        conversations[index].lastSenderId = senderId
        conversations[index].lastUpdated = message.date
        if text == nil {
            chatDraft = ""
        }
        Task { @MainActor in
            do {
                try await ChatService.send(message, in: conversation)
            } catch {
                alertMessage = "Couldn't send the message. \(error.localizedDescription)"
            }
        }
        return true
    }

    func markAsRead(conversationId: String, readerId: String) {
        guard let index = conversations.firstIndex(where: { $0.id == conversationId }),
              conversations[index].unreadCount(for: readerId) > 0 else { return }
        conversations[index].unread[readerId] = 0
        Task { try? await ChatService.markRead(conversationId: conversationId, uid: readerId) }
    }

    // MARK: - Delete account

    @MainActor
    func deleteConversations(involving userId: String) async {
        let ids = conversations
            .filter { $0.renterId == userId || $0.ownerId == userId }
            .map(\.id)
        for id in ids {
            await ChatService.delete(conversationId: id)
        }
        conversations.removeAll { ids.contains($0.id) }
    }
}
