import SwiftUI

struct TrackingStepper: View {
    @Environment(\.palette) private var palette
    let booking: Booking

    private var steps: [(label: String, sub: String, done: Bool)] {
        [
            ("Pending", "Request submitted", true),
            (
                "Approved",
                booking.pickupTime.map { "Pickup · \(booking.location) · \($0)" } ?? "Awaiting owner confirmation",
                booking.isApprovedOrLater
            ),
            ("Picked Up", "Vehicle in use (Ongoing)", booking.status == .ongoing || booking.status == .completed),
            ("Returned", "Trip ended (Completed)", booking.status == .completed)
        ]
    }

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    let currentIndex = max(steps.filter(\.done).count - 1, 0)
                    let isCurrent = index == currentIndex
                    HStack(alignment: .top, spacing: 16) {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .stroke(step.done || isCurrent ? palette.yellow : palette.border, lineWidth: 2)
                                    .background(
                                        Circle().fill(step.done ? palette.yellow : palette.canvas)
                                    )
                                    .frame(width: 28, height: 28)
                                    .shadow(color: isCurrent && !step.done ? palette.yellow.opacity(0.35) : .clear, radius: 4)
                                if step.done {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(palette.onYellow)
                                }
                            }
                            if index < steps.count - 1 {
                                Rectangle()
                                    .fill(step.done ? palette.yellow : palette.border)
                                    .frame(width: 2, height: 24)
                            }
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.label)
                                .font(.system(size: 15, weight: isCurrent ? .bold : .medium))
                                .foregroundStyle(isCurrent ? palette.text : palette.muted)
                            Text(step.sub)
                                .font(.system(size: 13))
                                .foregroundStyle(palette.muted)
                        }
                        .padding(.bottom, index < steps.count - 1 ? 16 : 0)
                        .opacity(index > currentIndex && !step.done ? 0.4 : 1)
                    }
                }
            }
        }
    }
}
