import SwiftUI

struct GameHUDView: View {
    @ObservedObject var gameState: GameState
    @State private var showSkills = false

    var body: some View {
        VStack(spacing: 8) {
            // EXP gauge (blue/cyan)
            gaugeBar(
                icon: "⚡",
                label: "EXP",
                value: gameState.exp,
                maxValue: gameState.expToEvolve,
                colors: [.cyan, .blue],
                displayText: "\(gameState.exp)/\(gameState.expToEvolve)",
                trailingText: "→ Lv.\(gameState.level + 1)"
            )
            
            // Energy gauge (green/red)
            gaugeBar(
                icon: "❤️",
                label: "ENG",
                value: gameState.energy,
                maxValue: 100,
                colors: gameState.energy > 30 ? [.green, .mint] : [.red, .orange],
                displayText: "\(gameState.energy)/100"
            )

            // Skills list
            if !gameState.learnedSkills.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        showSkills.toggle()
                    }
                } label: {
                    HStack {
                        Text("📚 Skills (\(gameState.learnedSkills.count))")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: showSkills ? "chevron.up" : "chevron.down")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.caption)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                }

                if showSkills {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(gameState.learnedSkills, id: \.self) { skill in
                            HStack {
                                Text("・\(skill)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                        }
                    }
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Gauge Bar Component

    private func gaugeBar(
        icon: String,
        label: String,
        value: Int,
        maxValue: Int,
        colors: [Color],
        displayText: String,
        trailingText: String? = nil
    ) -> some View {
        HStack(spacing: 8) {
            Text(icon)
                .font(.title3)

            Text(label)
                .font(.caption.bold())
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 36, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: colors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geo.size.width * CGFloat(min(value, maxValue)) / CGFloat(max(maxValue, 1)),
                            height: 12
                        )
                        .animation(.spring(response: 0.4), value: value)
                }
            }
            .frame(height: 12)

            Text(displayText)
                .font(.caption.monospacedDigit().bold())
                .foregroundColor(colors.first ?? .white)

            if let trailing = trailingText {
                Text(trailing)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            Spacer()
            GameHUDView(gameState: {
                let gs = GameState()
                gs.exp = 65
                gs.level = 1
                gs.learnedSkills = ["X投稿", "Web検索"]
                return gs
            }())
        }
    }
}
