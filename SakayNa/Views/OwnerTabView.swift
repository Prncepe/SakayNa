import SwiftUI

struct OwnerTabView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var bookings: BookingController
    @EnvironmentObject private var messages: MessageController
    @State private var dashboardPath = NavigationPath()
    @State private var requestsPath = NavigationPath()
    @State private var messagesPath = NavigationPath()
    @State private var profilePath = NavigationPath()

    private var unreadMessages: Int {
        messages.unreadCount(for: auth.user.id)
    }

    private var showsFloatingBar: Bool {
        switch bookings.selectedTab {
        case .home: return dashboardPath.isEmpty
        case .bookings: return requestsPath.isEmpty
        case .messages: return messagesPath.isEmpty
        case .profile: return profilePath.isEmpty
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $bookings.selectedTab) {
                NavigationStack(path: $dashboardPath) {
                    OwnerDashboardView(path: $dashboardPath)
                        .navigationDestination(for: AppRoute.self) { route in
                            ownerDestination(route, path: $dashboardPath)
                        }
                }
                .tag(MainTab.home)
                .toolbar(.hidden, for: .tabBar)

                NavigationStack(path: $requestsPath) {
                    BookingRequestsView(path: $requestsPath)
                        .navigationDestination(for: AppRoute.self) { route in
                            ownerDestination(route, path: $requestsPath)
                        }
                }
                .tag(MainTab.bookings)
                .toolbar(.hidden, for: .tabBar)

                NavigationStack(path: $messagesPath) {
                    MessagesListView(path: $messagesPath)
                        .navigationDestination(for: AppRoute.self) { route in
                            ownerDestination(route, path: $messagesPath)
                        }
                }
                .tag(MainTab.messages)
                .badge(unreadMessages)
                .toolbar(.hidden, for: .tabBar)

                NavigationStack(path: $profilePath) {
                    ProfileView(path: $profilePath)
                        .navigationDestination(for: AppRoute.self) { route in
                            profileDestination(route)
                        }
                }
                .tag(MainTab.profile)
                .toolbar(.hidden, for: .tabBar)
            }

            if showsFloatingBar {
                FloatingTabBar(
                    selectedTab: $bookings.selectedTab,
                    role: .owner,
                    unreadMessages: unreadMessages
                )
                .padding(.bottom, 16)
            }

            if bookings.showNotifications {
                NotificationsPanelView()
            }
        }
        .onChange(of: bookings.homeResetToken) { _, _ in
            dashboardPath = NavigationPath()
        }
        .onChange(of: bookings.bookingsResetToken) { _, _ in
            requestsPath = NavigationPath()
        }
        .onChange(of: bookings.messagesResetToken) { _, _ in
            messagesPath = NavigationPath()
        }
        .onChange(of: bookings.profileResetToken) { _, _ in
            profilePath = NavigationPath()
        }
        .onChange(of: bookings.pendingDestination) { _, route in
            openPending(route)
        }
    }

    @ViewBuilder
    private func ownerDestination(_ route: AppRoute, path: Binding<NavigationPath>) -> some View {
        switch route {
        case .addVehicle:
            AddVehicleView(path: path)
        case .tripTracking(let id):
            TripTrackingView(path: path, bookingId: id)
        case .chat(let id):
            ChatView(path: path, conversationId: id)
        case .rateTrip(let id):
            RateTripView(path: path, bookingId: id)
        case .receipt(let id):
            ReceiptView(path: path, bookingId: id)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func profileDestination(_ route: AppRoute) -> some View {
        switch route {
        case .editProfile:
            EditProfileView(path: $profilePath)
        case .paymentMethods:
            PaymentMethodsView(path: $profilePath)
        case .helpSupport:
            HelpSupportView(path: $profilePath)
        case .notificationSettings:
            NotificationSettingsView(path: $profilePath)
        case .termsAndConditions:
            TermsScreenView(path: $profilePath)
        case .privacyPolicy:
            PrivacyPolicyView(path: $profilePath)
        case .about:
            AboutView(path: $profilePath)
        case .verifyAccount:
            VerifyAccountView(path: $profilePath)
        default:
            EmptyView()
        }
    }

    private func openPending(_ route: AppRoute?) {
        guard let route else { return }
        DispatchQueue.main.async {
            switch route {
            case .chat:
                bookings.selectedTab = .messages
                messagesPath.append(route)
            case .tripTracking, .rateTrip, .receipt:
                bookings.selectedTab = .bookings
                requestsPath.append(route)
            case .addVehicle:
                bookings.selectedTab = .home
                dashboardPath.append(route)
            case .editProfile, .paymentMethods, .helpSupport, .notificationSettings,
                    .termsAndConditions, .privacyPolicy, .about, .verifyAccount:
                bookings.selectedTab = .profile
                profilePath.append(route)
            default:
                break
            }
            bookings.pendingDestination = nil
        }
    }
}
