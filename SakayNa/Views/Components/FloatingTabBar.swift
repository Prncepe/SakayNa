import SwiftUI

struct FloatingTabBar: View {
    @Environment(\.palette) private var palette
    @Binding var selectedTab: MainTab
    var role: UserRole = .renter
    var unreadMessages: Int = 0
    var onSearch: () -> Void = {}

    var body: some View {
        HStack(spacing: 4) {
            if role == .owner {
                tabButton(tab: .home, systemName: "square.grid.2x2.fill", label: "Home")
                tabButton(tab: .bookings, systemName: "doc.text.fill", label: "Requests")
                tabButton(tab: .messages, systemName: "ellipsis.message.fill", label: "Messages", badge: unreadMessages)
                tabButton(tab: .profile, systemName: "person.fill", label: "Profile")
            } else {
                tabButton(tab: .home, systemName: "house.fill", label: "Home")
                Button(action: onSearch) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(palette.muted)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Search")
                tabButton(tab: .bookings, systemName: "calendar", label: "Bookings")
                tabButton(tab: .messages, systemName: "ellipsis.message.fill", label: "Messages", badge: unreadMessages)
                tabButton(tab: .profile, systemName: "person.fill", label: "Profile")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(palette.card)
        .overlay(Capsule().stroke(palette.border, lineWidth: 1))
        .clipShape(Capsule())
        .shadow(color: palette.shadow, radius: 18, y: 8)
    }

    private func tabButton(tab: MainTab, systemName: String, label: String, badge: Int = 0) -> some View {
        let isActive = selectedTab == tab
        return Button {
            selectedTab = tab
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: systemName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isActive ? palette.onYellow : palette.muted)
                    .frame(width: 44, height: 44)
                    .background(isActive ? palette.yellow : Color.clear)
                    .clipShape(Circle())

                if badge > 0 {
                    Text(badge > 9 ? "9+" : "\(badge)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(isActive ? palette.yellow : palette.onYellow)
                        .padding(.horizontal, 4)
                        .frame(minWidth: 16, minHeight: 16)
                        .background(isActive ? palette.onYellow : palette.yellow)
                        .clipShape(Capsule())
                        .offset(x: 2, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}
