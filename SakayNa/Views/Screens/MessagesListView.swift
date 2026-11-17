import SwiftUI

struct MessagesListView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var vehicles: VehicleController
    @EnvironmentObject private var messages: MessageController
    @Binding var path: NavigationPath

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            AppHeader()
            Text("Messages")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(palette.text)

            List {
                let inbox = messages.inbox(for: auth.user.id)
                if messages.isLoading && inbox.isEmpty {
                    LoadingStateView(message: "Loading messages…")
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                } else if inbox.isEmpty {
                    EmptyStateView(
                        systemImage: "bubble.left.and.bubble.right",
                        title: "No messages yet",
                        message: "When you message an owner or renter, the chat will show up here."
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(inbox) { conversation in
                        Button {
                            messages.markAsRead(conversationId: conversation.id, readerId: auth.user.id)
                            path.append(AppRoute.chat(conversation.id))
                        } label: {
                            row(conversation)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 88)
        .background(palette.canvas.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private func row(_ conversation: Conversation) -> some View {
        let other = auth.user(id: conversation.otherUserId(than: auth.user.id))
        let vehicle = vehicles.vehicle(id: conversation.vehicleId)
        let unread = conversation.unreadCount(for: auth.user.id)
        return AppCard {
            HStack(alignment: .top, spacing: 12) {
                Text(other?.initial ?? "?")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color(hexString: other?.avatarColorHex ?? "#2196F3"))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(other?.name ?? "SakayNa user")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(palette.text)
                        Spacer()
                        Text(conversation.lastUpdated.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 11))
                            .foregroundStyle(palette.muted)
                    }
                    Text(vehicle?.name ?? "Vehicle")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(palette.yellow)
                    Text(conversation.lastMessage?.text ?? "No messages yet.")
                        .font(.system(size: 13, weight: unread > 0 ? .semibold : .regular))
                        .foregroundStyle(unread > 0 ? palette.text : palette.muted)
                        .lineLimit(1)
                }

                if unread > 0 {
                    Circle()
                        .fill(palette.yellow)
                        .frame(width: 10, height: 10)
                        .padding(.top, 6)
                }
            }
        }
    }
}
