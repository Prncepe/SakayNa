import Foundation

enum AppFormat {
    static func peso(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_PH")
        let digits = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "₱\(digits)"
    }

    static func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }

    static func longDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.wide).day().year())
    }
}
