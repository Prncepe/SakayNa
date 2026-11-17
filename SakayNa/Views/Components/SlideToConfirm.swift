import SwiftUI

struct SlideToConfirm: View {
    @Environment(\.palette) private var palette
    let label: String
    var completedLabel: String = "Confirmed!"
    var isEnabled: Bool = true
    var playsHint: Bool = false
    let onComplete: () -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var completed = false
    @State private var trackWidth: CGFloat = 0

    private let height: CGFloat = 56
    private let thumb: CGFloat = 48
    private let inset: CGFloat = 4

    var body: some View {
        GeometryReader { geo in
            let maxX = max(geo.size.width - thumb - inset * 2, 1)
            let progress = min(max(dragOffset / maxX, 0), 1)

            ZStack {
                Capsule()
                    .fill(palette.slideTrack)

                HStack {
                    Capsule()
                        .fill(palette.yellow)
                        .frame(width: max(thumb + inset * 2, thumb + inset * 2 + dragOffset))
                    Spacer(minLength: 0)
                }

                Text(completed ? completedLabel : label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(completed ? palette.onYellow : palette.text.opacity(0.88))
                    .opacity(completed ? 1.0 : max(0.0, 1.0 - progress * 2))
                    .allowsHitTesting(false)

                HStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: thumb, height: thumb)
                        .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
                        .overlay {
                            Image(systemName: completed ? "checkmark" : "arrow.right")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(palette.onYellow)
                        }
                        .offset(x: inset + dragOffset)
                        .gesture(dragGesture(maxX: maxX))
                    Spacer()
                }
            }
            .onAppear {
                trackWidth = maxX
            }
            .onChange(of: geo.size.width) { _, _ in
                trackWidth = maxX
            }
        }
        .frame(height: height)
        .opacity(isEnabled ? 1 : 0.4)
        .allowsHitTesting(isEnabled && !completed)
        .onAppear {
            dragOffset = 0
            completed = false
            guard playsHint else { return }
            playHint()
        }
    }

    private func playHint() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            let hint = max(trackWidth * 0.32, 48)
            withAnimation(.easeInOut(duration: 0.65)) {
                dragOffset = hint
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                guard !completed else { return }
                withAnimation(.easeInOut(duration: 0.45)) {
                    dragOffset = 0
                }
            }
        }
    }

    private func dragGesture(maxX: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard !completed else { return }
                dragOffset = min(max(value.translation.width, 0), maxX)
            }
            .onEnded { _ in
                guard !completed else { return }
                if dragOffset / maxX > 0.85 {
                    withAnimation(.easeInOut(duration: 0.26)) {
                        dragOffset = maxX
                        completed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                        onComplete()
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.26)) {
                        dragOffset = 0
                    }
                }
            }
    }
}
