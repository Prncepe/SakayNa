import SwiftUI

struct NotificationsPanelView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var bookings: BookingController

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.opacity(0.28)
                .ignoresSafeArea()
                .onTapGesture {
                    bookings.showNotifications = false
                }

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Notifications")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(palette.text)
                    Spacer()
                    Button {
                        bookings.showNotifications = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(palette.muted)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                Rectangle()
                    .fill(palette.border)
                    .frame(height: 1)

                if bookings.isLoadingNotifications && bookings.notifications.isEmpty {
                    LoadingStateView(message: "Loading notifications…", compact: true)
                        .padding(.vertical, 20)
                } else if bookings.notifications.isEmpty {
                    EmptyStateView(
                        systemImage: "bell.slash",
                        title: "No notifications",
                        message: "Booking updates will show up here.",
                        compact: true
                    )
                    .padding(.vertical, 20)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(bookings.notifications) { item in
                                Button {
                                    bookings.openNotification(item.id)
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.message)
                                            .font(.system(size: 13, weight: item.isRead ? .regular : .bold))
                                            .foregroundStyle(palette.text)
                                            .multilineTextAlignment(.leading)
                                        Text(item.timestamp.formatted(date: .omitted, time: .shortened))
                                            .font(.system(size: 11))
                                            .foregroundStyle(palette.muted)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .frame(width: 300)
            .frame(maxHeight: 420)
            .background(palette.canvas)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(palette.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: palette.shadow, radius: 16, y: 8)
            .padding(.top, 64)
            .padding(.trailing, 16)
        }
    }
}
