import SwiftUI

struct AppHeader: View {
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var bookings: BookingController

    var title: String?
    var showsBack: Bool = false
    var showsProfileActions: Bool = true
    var onBack: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            if showsBack {
                IconCircleButton(systemName: "chevron.left") {
                    if let onBack {
                        onBack()
                    } else {
                        dismiss()
                    }
                }
            } else {
                BrandMark()
            }

            if let title {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(palette.text)
                    .frame(maxWidth: .infinity)
            } else {
                Spacer()
            }

            if showsProfileActions {
                Button {
                    bookings.selectedTab = .profile
                    bookings.profileResetToken += 1
                } label: {
                    Text(auth.user.initial)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color(hexString: auth.user.avatarColorHex))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button {
                    bookings.showNotifications.toggle()
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(palette.text)
                            .frame(width: 36, height: 36)
                            .background(palette.card)
                            .overlay(Circle().stroke(palette.border, lineWidth: 1))
                        if bookings.unreadCount > 0 {
                            Circle()
                                .fill(palette.yellow)
                                .frame(width: 7, height: 7)
                                .offset(x: -4, y: 4)
                        }
                    }
                }
                .buttonStyle(.plain)
            } else if title != nil {
                Color.clear.frame(width: 36, height: 36)
            }
        }
    }
}
