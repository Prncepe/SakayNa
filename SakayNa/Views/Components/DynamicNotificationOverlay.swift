import SwiftUI

struct DynamicNotificationOverlay: View {
    let notification: AppNotification?
    var onOpen: (AppNotification) -> Void
    var onDismiss: () -> Void

    @State private var shown: AppNotification?
    @State private var drop: CGFloat = 0
    @State private var tint: CGFloat = 0
    @State private var expand: CGFloat = 0
    @State private var content: Double = 0
    @State private var dragY: CGFloat = 0
    @State private var token = UUID()

    private let islandTop: CGFloat = 11
    private let islandHeight: CGFloat = 37.33
    private let cardHeight: CGFloat = 74
    private let cardGap: CGFloat = 18
    private let dropSize: CGFloat = 44
    private let accent = Color(hex: 0x2F9BFF)

    private var islandBottom: CGFloat { islandTop + islandHeight }

    var body: some View {
        GeometryReader { geo in
            let cardWidth = min(396, geo.size.width - 32)
            ZStack(alignment: .top) {
                if shown != nil {
                    blob(cardWidth: cardWidth, canvasWidth: geo.size.width)
                        .offset(y: dragY)
                        .gesture(swipe)
                        .onTapGesture {
                            guard let shown, expand > 0.8 else { return }
                            playExit { onOpen(shown) }
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(shown != nil && expand > 0.8)
        .onChange(of: notification?.id) { _, _ in
            handleChange()
        }
        .onAppear(perform: handleChange)
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                dragY = min(0, value.translation.height)
            }
            .onEnded { value in
                if value.translation.height <= -18 || value.predictedEndTranslation.height <= -80 {
                    playExit(nil)
                } else {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                        dragY = 0
                    }
                }
            }
    }

    private func blob(cardWidth: CGFloat, canvasWidth: CGFloat) -> some View {
        let cardTop = islandBottom + cardGap
        let dropTop = islandBottom - 10 + drop * (cardTop - (islandBottom - 10))
        let width = dropSize + (cardWidth - dropSize) * expand
        let height = dropSize + (cardHeight - dropSize) * expand
        let blobColor = Color(red: tint, green: tint, blue: tint)
        let neckWidth = 20 + 16 * (1 - expand)
        let neckHeight = max(dropTop - islandBottom + 18, 8) * (1 - min(expand / 0.82, 1))

        return ZStack(alignment: .top) {
            Canvas { context, size in
                var filtered = context
                filtered.addFilter(.alphaThreshold(min: 0.45, color: blobColor))
                filtered.addFilter(.blur(radius: 8 + 6 * (1 - expand)))
                filtered.drawLayer { layer in
                    if neckHeight > 4 {
                        let neck = CGRect(
                            x: (size.width - neckWidth) / 2,
                            y: islandBottom - 8,
                            width: neckWidth,
                            height: neckHeight
                        )
                        layer.fill(
                            Path(roundedRect: neck, cornerRadius: neckWidth / 2),
                            with: .color(blobColor)
                        )
                    }

                    let rect = CGRect(
                        x: (size.width - width) / 2,
                        y: dropTop,
                        width: width,
                        height: height
                    )
                    layer.fill(
                        Path(roundedRect: rect, cornerRadius: height / 2),
                        with: .color(blobColor)
                    )
                }
            }
            .shadow(
                color: Color.black.opacity(0.18 * expand),
                radius: 14,
                y: 10
            )

            cardBody(width: cardWidth)
                .frame(width: width, height: height)
                .offset(y: dropTop)
                .opacity(content)
        }
        .frame(width: canvasWidth, height: cardTop + cardHeight + 24)
    }

    private func cardBody(width: CGFloat) -> some View {
        HStack(spacing: 10) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 46, height: 46)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(shown?.bannerTitle ?? "SakayNa")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(accent)
                    .lineLimit(1)
                Text(shown?.message ?? "")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(hex: 0x77787D))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Image(systemName: shown?.bannerSymbol ?? "bell.fill")
                .font(.system(size: 27, weight: .semibold))
                .foregroundStyle(accent)
        }
        .padding(.horizontal, 14)
        .frame(width: width, height: cardHeight)
    }

    private func handleChange() {
        token = UUID()
        let current = token
        if let notification {
            shown = notification
            playEnter(current)
        } else if shown != nil {
            playExit(nil)
        }
    }

    private func playEnter(_ current: UUID) {
        drop = 0
        tint = 0
        expand = 0
        content = 0
        dragY = 0

        withAnimation(.spring(response: 0.44, dampingFraction: 0.84)) {
            drop = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.11) {
            guard current == token else { return }
            withAnimation(.easeInOut(duration: 0.26)) {
                tint = 1
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
            guard current == token else { return }
            withAnimation(.spring(response: 0.48, dampingFraction: 0.82)) {
                expand = 1
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.56) {
            guard current == token else { return }
            withAnimation(.easeOut(duration: 0.22)) {
                content = 1
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.6) {
            guard current == token else { return }
            playExit(nil)
        }
    }

    private func playExit(_ after: (() -> Void)?) {
        let current = token
        withAnimation(.easeIn(duration: 0.14)) {
            content = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            guard current == token else { return }
            withAnimation(.spring(response: 0.36, dampingFraction: 0.9)) {
                expand = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            guard current == token else { return }
            withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
                tint = 0
                drop = 0
                dragY = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            guard current == token else { return }
            shown = nil
            onDismiss()
            after?()
        }
    }
}
