import SwiftUI
import AVKit
import AVFoundation

struct WelcomeView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var auth: AuthController

    @State private var player: AVPlayer?
    @State private var videoDone = false
    @State private var showLogo = false
    @State private var showEyebrow = false
    @State private var showTitle = false
    @State private var showTagline = false
    @State private var showPill = false
    @State private var goNext = false
    @State private var knobX: CGFloat = 0
    @State private var endObserver: NSObjectProtocol?

    var body: some View {
        ZStack {
            palette.canvas.ignoresSafeArea()

            // Full-screen intro; stays on the last frame when finished
            if let player {
                IntroPlayerView(player: player)
                    .opacity(1)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            if videoDone {
                VStack(alignment: .leading, spacing: 0) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .modifier(FadeUp(shown: showLogo))
                        .padding(.top, 8)

                    Text("WELCOME TO")
                        .font(.system(size: 13, weight: .medium))
                        .tracking(1.6)
                        .foregroundStyle(palette.muted)
                        .modifier(FadeUp(shown: showEyebrow))
                        .padding(.top, 28)

                    Text("SakayNa")
                        .font(.system(size: 42, weight: .heavy))
                        .tracking(-0.8)
                        .foregroundStyle(palette.text)
                        .modifier(FadeUp(shown: showTitle))

                    Text("Find, Book, and Ride the perfect vehicle for every journey.")
                        .font(.system(size: 15))
                        .foregroundStyle(palette.muted)
                        .frame(maxWidth: 280, alignment: .leading)
                        .modifier(FadeUp(shown: showTagline))
                        .padding(.top, 10)

                    Spacer()

                    slidePill
                        .modifier(FadeUp(shown: showPill))
                        .padding(.bottom, 12)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $goNext) {
            LoginView()
                .navigationBarBackButtonHidden(true)
        }
        .onAppear(perform: startVideo)
        .onDisappear {
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
            }
        }
        .onChange(of: goNext) { _, presented in
            if !presented { knobX = 0 }
        }
        .onChange(of: videoDone) { _, done in
            if done { playIntro() }
        }
    }

    // Yellow knob starts on the LEFT; text stays put
    private var slidePill: some View {
        GeometryReader { geo in
            let thumb: CGFloat = 52
            let inset: CGFloat = 6
            let maxX = geo.size.width - thumb - inset * 2

            ZStack {
                Capsule().fill(Color.white)

                Text("GET START FOR RIDE")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1.1)
                    .foregroundStyle(palette.text)
                    .allowsHitTesting(false)

                HStack {
                    Circle()
                        .fill(palette.yellow)
                        .frame(width: thumb, height: thumb)
                        .overlay {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(palette.onYellow)
                        }
                        .offset(x: inset + knobX)
                        .gesture(dragKnob(maxX: maxX))
                    Spacer()
                }
            }
        }
        .frame(height: 64)
        .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
    }

    private func dragKnob(maxX: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                knobX = min(max(value.translation.width, 0), maxX)
            }
            .onEnded { _ in
                if knobX / maxX > 0.8 {
                    withAnimation(.easeOut(duration: 0.2)) { knobX = maxX }
                    auth.goToLogin()
                    goNext = true
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
                        knobX = 0
                    }
                }
            }
    }

    private func startVideo() {
        guard let url = introURL() else {
            videoDone = true
            return
        }

        let item = AVPlayerItem(url: url)
        let av = AVPlayer(playerItem: item)
        av.isMuted = true
        player = av

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { _ in
            // Leave the last frame on screen
            videoDone = true
        }

        av.play()
    }

    // Try Appintro/intro.MP4, then flatten / lowercase fallbacks
    private func introURL() -> URL? {
        let bundle = Bundle.main
        if let url = bundle.url(forResource: "intro", withExtension: "MP4", subdirectory: "Appintro") {
            return url
        }
        if let url = bundle.url(forResource: "intro", withExtension: "MP4") {
            return url
        }
        if let url = bundle.url(forResource: "intro", withExtension: "mp4") {
            return url
        }
        print("intro video not found in bundle")
        return nil
    }

    private func playIntro() {
        withAnimation(.easeOut(duration: 0.45)) { showLogo = true }
        withAnimation(.easeOut(duration: 0.45).delay(0.12)) { showEyebrow = true }
        withAnimation(.easeOut(duration: 0.45).delay(0.24)) { showTitle = true }
        withAnimation(.easeOut(duration: 0.45).delay(0.36)) { showTagline = true }
        withAnimation(.easeOut(duration: 0.45).delay(0.48)) { showPill = true }
    }
}

// Full-bleed AVPlayerLayer, no controls
private struct IntroPlayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        PlayerUIView(player: player)
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.player = player
    }
}

private final class PlayerUIView: UIView {
    private let playerLayer = AVPlayerLayer()

    var player: AVPlayer? {
        didSet { playerLayer.player = player }
    }

    init(player: AVPlayer) {
        super.init(frame: .zero)
        backgroundColor = .black
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

private struct FadeUp: ViewModifier {
    let shown: Bool

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 18)
    }
}
