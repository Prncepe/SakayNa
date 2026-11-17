import Foundation
import UserNotifications

final class LocalNotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = LocalNotificationService()
    var isEnabled = true
    var isAppActive = true

    func configure() {
        UNUserNotificationCenter.current().delegate = self
        isEnabled = UserDefaults.standard.object(forKey: "pref.notificationsEnabled") as? Bool ?? true
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func fire(title: String, body: String) {
        guard isEnabled, !isAppActive else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleBookingReminders(for booking: Booking) {
        cancelBookingReminders(bookingId: booking.id)
        guard isEnabled else { return }
        guard booking.status == .approved || booking.status == .ongoing else { return }
        let pickup = Self.combinedDate(day: booking.startDate, timeText: booking.pickupTime ?? "10:00 AM")
        let returnAt = Self.combinedDate(day: booking.endDate, timeText: booking.pickupTime ?? "10:00 AM")
        schedule(
            id: Self.pickupId(booking.id),
            title: "Pickup soon",
            body: "Your \(booking.vehicle.name) pickup is in 1 hour.",
            at: pickup.addingTimeInterval(-3600)
        )
        schedule(
            id: Self.returnId(booking.id),
            title: "Return soon",
            body: "Please return \(booking.vehicle.name) in 2 hours.",
            at: returnAt.addingTimeInterval(-7200)
        )
        if booking.status != .completed {
            schedule(
                id: Self.lateId(booking.id),
                title: "Return is overdue",
                body: "Your \(booking.vehicle.name) rental is 1 hour past the return time.",
                at: returnAt.addingTimeInterval(3600)
            )
        }
    }

    func cancelBookingReminders(bookingId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [
                Self.pickupId(bookingId),
                Self.returnId(bookingId),
                Self.lateId(bookingId)
            ]
        )
    }

    func cancelAllBookingReminders() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix("sakayna-") }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    func scheduleTestReminder() {
        guard isEnabled else { return }
        requestPermission()
        let content = UNMutableNotificationContent()
        content.title = "Test reminder"
        content.body = "This is a SakayNa test reminder."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let request = UNNotificationRequest(
            identifier: "sakayna-test-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if notification.request.identifier.hasPrefix("sakayna-test") {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([])
        }
    }

    private func schedule(id: String, title: String, body: String, at date: Date) {
        guard date > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func combinedDate(day: Date, timeText: String) -> Date {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let formats = ["h:mm a", "hh:mm a", "H:mm", "HH:mm"]
        for format in formats {
            formatter.dateFormat = format
            if let time = formatter.date(from: timeText) {
                let timeParts = calendar.dateComponents([.hour, .minute], from: time)
                var parts = calendar.dateComponents([.year, .month, .day], from: day)
                parts.hour = timeParts.hour
                parts.minute = timeParts.minute
                return calendar.date(from: parts) ?? day
            }
        }
        var parts = calendar.dateComponents([.year, .month, .day], from: day)
        parts.hour = 10
        parts.minute = 0
        return calendar.date(from: parts) ?? day
    }

    private static func pickupId(_ bookingId: String) -> String { "sakayna-pickup-\(bookingId)" }
    private static func returnId(_ bookingId: String) -> String { "sakayna-return-\(bookingId)" }
    private static func lateId(_ bookingId: String) -> String { "sakayna-late-\(bookingId)" }
}
