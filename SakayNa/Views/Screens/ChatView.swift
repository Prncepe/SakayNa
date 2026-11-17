import SwiftUI

struct ChatView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var vehicles: VehicleController
    @EnvironmentObject private var bookings: BookingController
    @EnvironmentObject private var messages: MessageController
    @Binding var path: NavigationPath
    let conversationId: String
    @State private var showReport = false
    @State private var showBlockConfirm = false
    @State private var reportSaved = false

    var body: some View {
        Group {
            if let conversation = messages.conversation(id: conversationId) {
                chat(conversation)
            } else if messages.isLoading {
                LoadingStateView(message: "Loading chat…")
            } else {
                Text("Chat unavailable")
                    .foregroundStyle(palette.muted)
            }
        }
        .background(palette.canvas.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            messages.openChat(conversationId)
            messages.markAsRead(conversationId: conversationId, readerId: auth.user.id)
        }
        .onDisappear {
            messages.closeChat(conversationId)
        }
        .onChange(of: messages.conversation(id: conversationId)?.unreadCount(for: auth.user.id) ?? 0) { _, count in
            if count > 0 {
                messages.markAsRead(conversationId: conversationId, readerId: auth.user.id)
            }
        }
        .confirmationDialog("Report user", isPresented: $showReport, titleVisibility: .visible) {
            ForEach(ReportReason.allCases, id: \.self) { reason in
                Button(reason.rawValue) {
                    if let conversation = messages.conversation(id: conversationId) {
                        messages.reportUser(
                            reporterId: auth.user.id,
                            reportedUserId: conversation.otherUserId(than: auth.user.id),
                            reason: reason,
                            conversationId: conversation.id
                        )
                        reportSaved = true
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Report saved", isPresented: $reportSaved) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Thanks. Your report was sent to the SakayNa team.")
        }
        .alert("Block this user?", isPresented: $showBlockConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Block", role: .destructive) {
                if let conversation = messages.conversation(id: conversationId) {
                    messages.blockUser(
                        blockerId: auth.user.id,
                        blockedUserId: conversation.otherUserId(than: auth.user.id)
                    )
                    if !path.isEmpty { path.removeLast() }
                }
            }
        } message: {
            Text("Their conversation will be hidden and they won't be able to message you.")
        }
    }

    private func chat(_ conversation: Conversation) -> some View {
        let vehicleName = vehicles.vehicle(id: conversation.vehicleId)?.name ?? "Vehicle"
        let other = auth.user(id: conversation.otherUserId(than: auth.user.id))
        return VStack(spacing: 0) {
            HStack(spacing: 12) {
                IconCircleButton(systemName: "chevron.left") {
                    if !path.isEmpty { path.removeLast() }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(other?.name ?? "Deleted user")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(palette.text)
                    if other?.isVerifiedOwner == true {
                        VerifiedOwnerBadge(compact: true)
                    }
                    Text(vehicleName)
                        .font(.system(size: 13))
                        .foregroundStyle(palette.muted)
                }
                Spacer()
                Menu {
                    Button("Report") { showReport = true }
                    Button("Block", role: .destructive) { showBlockConfirm = true }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(palette.text)
                        .frame(width: 36, height: 36)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    if messages.isLoadingChat && conversation.messages.isEmpty {
                        LoadingStateView(message: "Loading messages…")
                    } else if conversation.messages.isEmpty {
                        Text("No messages yet.")
                            .font(.system(size: 13))
                            .foregroundStyle(palette.muted)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 32)
                    }
                    ForEach(conversation.messages) { message in
                        let isMe = message.senderId == auth.user.id
                        VStack(alignment: isMe ? .trailing : .leading, spacing: 2) {
                            Text(message.text)
                                .font(.system(size: 14))
                                .foregroundStyle(isMe ? palette.onYellow : palette.text)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(isMe ? palette.yellow : palette.card)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            Text(message.date.formatted(date: .omitted, time: .shortened))
                                .font(.system(size: 11))
                                .foregroundStyle(palette.muted)
                        }
                        .frame(maxWidth: .infinity, alignment: isMe ? .trailing : .leading)
                    }
                }
                .padding(.horizontal, 24)
            }

            let otherId = conversation.otherUserId(than: auth.user.id)
            if !messages.canMessage(from: auth.user.id, to: otherId) {
                Text("You can't message this user.")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(palette.muted)
                    .frame(maxWidth: .infinity)
                    .padding(16)
            } else {
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $messages.chatDraft)
                        .padding(.horizontal, 20)
                        .frame(height: 48)
                        .background(palette.fieldFill)
                        .overlay(Capsule().stroke(palette.border, lineWidth: 1))
                        .clipShape(Capsule())
                        .foregroundStyle(palette.text)
                        .onSubmit {
                            send(conversation)
                        }
                    Button {
                        send(conversation)
                    } label: {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(palette.onYellow)
                            .frame(width: 48, height: 48)
                            .background(palette.yellow)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .overlay(alignment: .top) {
                    Rectangle().fill(palette.border).frame(height: 1)
                }
            }
        }
    }

    private func send(_ conversation: Conversation) {
        let text = messages.chatDraft
        let sent = messages.send(conversationId: conversation.id, senderId: auth.user.id)
        if sent && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let vehicleName = vehicles.vehicle(id: conversation.vehicleId)?.name ?? "a vehicle"
            bookings.addNotification(
                "New message about \(vehicleName).",
                conversationId: conversation.id,
                recipientId: conversation.otherUserId(than: auth.user.id)
            )
        }
    }
}
