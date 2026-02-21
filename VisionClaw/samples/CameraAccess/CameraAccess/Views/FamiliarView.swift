import SwiftUI
import UIKit
import AVFoundation

// MARK: - VideoPlayerView (UIViewRepresentable)

struct VideoPlayerView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear

        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        player.isMuted = true           // 使い魔動画は無音ループ
        player.actionAtItemEnd = .none   // 自動停止しない

        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        containerView.layer.addSublayer(playerLayer)

        context.coordinator.player = player
        context.coordinator.playerLayer = playerLayer

        // ループ再生: 再生完了通知を監視して先頭にシーク
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.playerItemDidReachEnd(_:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        player.play()
        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // レイアウト更新時にplayerLayerのframeを合わせる
        DispatchQueue.main.async {
            context.coordinator.playerLayer?.frame = uiView.bounds
        }

        // URLが変わった場合はプレイヤーを差し替え
        if context.coordinator.currentURL != url {
            context.coordinator.currentURL = url

            // 旧playerItemの通知を解除
            NotificationCenter.default.removeObserver(context.coordinator,
                                                       name: .AVPlayerItemDidPlayToEndTime,
                                                       object: context.coordinator.player?.currentItem)

            let newItem = AVPlayerItem(url: url)
            context.coordinator.player?.replaceCurrentItem(with: newItem)

            NotificationCenter.default.addObserver(
                context.coordinator,
                selector: #selector(Coordinator.playerItemDidReachEnd(_:)),
                name: .AVPlayerItemDidPlayToEndTime,
                object: newItem
            )

            context.coordinator.player?.seek(to: .zero)
            context.coordinator.player?.play()
        }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.player?.pause()
        NotificationCenter.default.removeObserver(coordinator)
        coordinator.player = nil
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    class Coordinator: NSObject {
        var player: AVPlayer?
        var playerLayer: AVPlayerLayer?
        var currentURL: URL

        init(url: URL) {
            self.currentURL = url
            super.init()
        }

        @objc func playerItemDidReachEnd(_ notification: Notification) {
            player?.seek(to: .zero)
            player?.play()
        }
    }
}

// MARK: - FamiliarView

struct FamiliarView: View {
    @ObservedObject var gameState: GameState
    var aiTranscript: String

    @State private var isBreathing = false
    @State private var evolutionGlow = false
    @State private var evolutionSpin = false

    var body: some View {
        ZStack {
            // Evolution overlay
            if gameState.isEvolving {
                evolutionOverlay
            }

            VStack(spacing: 12) {
                ZStack {
                    if gameState.isDead {
                        VStack {
                            Text("🪦")
                                .font(.system(size: 80))
                                .shadow(color: .green.opacity(0.8), radius: 20)
                            Text("SYSTEM TERMINATED")
                                .font(.headline)
                                .foregroundColor(.red)
                                .padding(.top, 8)
                        }
                    } else if let activeVideoURL = gameState.isHappy && gameState.currentHappyVideoURL != nil ? gameState.currentHappyVideoURL : gameState.currentVideoURL {
                        VideoPlayerView(url: activeVideoURL)
                            .id(activeVideoURL) // IDを変えてプレイヤーを強制再構築（またはupdateUIViewに任せる）
                    } else if let imageURL = gameState.currentVisualURL {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFit()
                                    .shadow(color: .cyan.opacity(0.8), radius: 20, x: 0, y: 0)
                                    .shadow(color: .blue.opacity(0.5), radius: 40, x: 0, y: 0)
                            case .failure:
                                placeholderView
                            default:
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(.white)
                            }
                        }
                    } else {
                        placeholderView
                    }
                }
                .frame(width: 280, height: 280)
                // Only apply breathing animation when showing static image (not video)
                .offset(y: !gameState.isDead && gameState.currentVideoURL == nil ? (isBreathing ? -12 : 12) : 0)
                .animation(
                    !gameState.isDead && gameState.currentVideoURL == nil
                        ? .easeInOut(duration: 1.5).repeatForever(autoreverses: true)
                        : .default,
                    value: isBreathing
                )
                // Happy bounce
                .scaleEffect(gameState.isHappy ? 1.15 : 1.0)
                .rotationEffect(.degrees(gameState.isHappy ? 8 : 0))
                .animation(.spring(response: 0.2, dampingFraction: 0.2), value: gameState.isHappy)
                // Evolution flash
                .scaleEffect(gameState.isEvolving ? 1.3 : 1.0)
                .brightness(gameState.isEvolving ? 0.3 : 0)
                .animation(.easeInOut(duration: 0.6).repeatCount(3, autoreverses: true), value: gameState.isEvolving)

                // Name + Level
                Text("【\(gameState.name.isEmpty ? "Creature" : gameState.name)】 Lv.\(gameState.level)")
                    .font(.headline)
                    .foregroundColor(gameState.isDead ? .gray : (gameState.isEvolving ? .yellow : .white))
                    .shadow(color: gameState.isDead ? .clear : (gameState.isEvolving ? .yellow.opacity(0.9) : .cyan.opacity(0.8)), radius: gameState.isDead ? 0 : 8)
                    .animation(.easeInOut(duration: 0.5), value: gameState.isEvolving)

                // Evolution banner
                if gameState.isEvolving && !gameState.isDead {
                    Text("★ EVOLVED to Lv.\(gameState.level)! ★")
                        .font(.title3.bold())
                        .foregroundColor(.yellow)
                        .shadow(color: .orange, radius: 12)
                        .transition(.scale.combined(with: .opacity))
                }

                // Transcript
                if !aiTranscript.isEmpty {
                    Text(aiTranscript)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.4))
                        )
                        .lineLimit(3)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .animation(.spring(response: 0.5), value: gameState.isEvolving)
        .onAppear {
            isBreathing = true
        }
    }

    // MARK: - Evolution Overlay

    private var evolutionOverlay: some View {
        ZStack {
            // Radial glow burst
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.yellow.opacity(0.6), .orange.opacity(0.3), .clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .scaleEffect(evolutionGlow ? 1.5 : 0.3)
                .opacity(evolutionGlow ? 0.0 : 1.0)
                .animation(.easeOut(duration: 2.0), value: evolutionGlow)

            // Spinning sparkle ring
            ForEach(0..<8, id: \.self) { i in
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 6, height: 6)
                    .offset(y: -120)
                    .rotationEffect(.degrees(Double(i) * 45 + (evolutionSpin ? 360 : 0)))
                    .animation(
                        .linear(duration: 2.0).repeatCount(2, autoreverses: false),
                        value: evolutionSpin
                    )
            }
        }
        .onAppear {
            evolutionGlow = true
            evolutionSpin = true
        }
        .onDisappear {
            evolutionGlow = false
            evolutionSpin = false
        }
    }

    private var placeholderView: some View {
        Text("\u{1F95A}")
            .font(.system(size: 100))
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        FamiliarView(
            gameState: {
                let gs = GameState()
                gs.level = 2
                return gs
            }(),
            aiTranscript: "新しいダンジョンだ！わくわくする！"
        )
    }
}
