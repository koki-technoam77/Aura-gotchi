import Foundation
import Combine

@MainActor
class GameState: ObservableObject {
    @Published var exp: Int = 0
    @Published var level: Int = 1
    @Published var baseAttributes: String = "cute generic creature"
    @Published var name: String = ""
    @Published var currentVisualURL: URL?
    @Published var currentVideoURL: URL?        // Idle Video
    @Published var currentHappyVideoURL: URL?   // Happy/Success Video
    @Published var behaviorPrompt: String = ""
    @Published var personalityPrompt: String = ""
    @Published var learnedSkills: [String] = []
    @Published var isHappy: Bool = false
    @Published var isEvolving: Bool = false
    
    // MARK: - Tamagotchi Status
    @Published var energy: Int = 100 // 総合的な体力/空腹/精神状態（0〜100）
    @Published var isDead: Bool = false

    var expToEvolve: Int {
        switch level {
        case 1: return 30
        case 2: return 100
        case 3: return 300
        default: return 600
        }
    }

    init() {
        // Fresh start per session (character creation screen first)
    }

    func addExp(_ amount: Int) {
        if isDead { return }
        exp += max(0, amount)
        save()
    }
    
    func changeEnergy(_ amount: Int) {
        if isDead { return }
        energy = max(0, min(100, energy + amount))
        if energy <= 0 {
            isDead = true
        }
        save()
    }

    func checkEvolution() -> Bool {
        if exp >= expToEvolve {
            exp -= expToEvolve
            level += 1
            save()
            triggerEvolution()
            return true
        }
        return false
    }

    func addSkill(_ skillName: String) {
        if !learnedSkills.contains(skillName) {
            learnedSkills.append(skillName)
            save()
        }
    }

    /// Skills list as prompt text for Gemini
    var skillsPromptSuffix: String {
        guard !learnedSkills.isEmpty else { return "" }
        return "\n\n※以下のスキルを習得済み: " + learnedSkills.joined(separator: ", ")
    }

    /// Dynamic prompt suffix: name + personality + skills for Gemini system prompt
    var dynamicPromptSuffix: String {
        var suffix = ""
        if !name.isEmpty {
            suffix += "\n\n## あなたの名前\n\(name)"
        }
        if !personalityPrompt.isEmpty {
            suffix += "\n\n## あなたのキャラ設定\n\(personalityPrompt)"
        }
        suffix += "\n\n## 現在のステータス\nEnergy: \(energy)/100\(isDead ? " 【DEAD】" : "")"
        if !learnedSkills.isEmpty {
            suffix += "\n\n※以下のスキルを習得済み: " + learnedSkills.joined(separator: ", ")
        }
        return suffix
    }

    /// Evolution animation (3 seconds)
    func triggerEvolution() {
        isEvolving = true
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            self?.isEvolving = false
        }
    }

    /// Happy bounce animation (0.8 seconds)
    func triggerHappy() {
        isHappy = true
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 800_000_000)
            self?.isHappy = false
        }
    }

    // MARK: - Persistence

    private static let storageKey = "aura_gotchi_state"

    private struct SaveData: Codable {
        var exp: Int
        var level: Int
        var baseAttributes: String
        var name: String
        var currentVisualURL: String?
        var currentVideoURL: String?
        var currentHappyVideoURL: String?
        var behaviorPrompt: String?
        var personalityPrompt: String?
        var learnedSkills: [String]
        var energy: Int
        var isDead: Bool
    }

    func save() {
        let data = SaveData(
            exp: exp,
            level: level,
            baseAttributes: baseAttributes,
            name: name,
            currentVisualURL: currentVisualURL?.absoluteString,
            currentVideoURL: currentVideoURL?.absoluteString,
            currentHappyVideoURL: currentHappyVideoURL?.absoluteString,
            behaviorPrompt: behaviorPrompt,
            personalityPrompt: personalityPrompt,
            learnedSkills: learnedSkills,
            energy: energy,
            isDead: isDead
        )
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: Self.storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode(SaveData.self, from: data) else {
            return
        }
        exp = decoded.exp
        level = decoded.level
        baseAttributes = decoded.baseAttributes
        name = decoded.name
        if let urlString = decoded.currentVisualURL {
            currentVisualURL = URL(string: urlString)
        }
        if let urlString = decoded.currentVideoURL {
            currentVideoURL = URL(string: urlString)
        }
        if let urlString = decoded.currentHappyVideoURL {
            currentHappyVideoURL = URL(string: urlString)
        }
        behaviorPrompt = decoded.behaviorPrompt ?? ""
        personalityPrompt = decoded.personalityPrompt ?? ""
        learnedSkills = decoded.learnedSkills
        energy = decoded.energy
        isDead = decoded.isDead
    }

    /// Reset for demo
    func reset() {
        exp = 0
        level = 1
        baseAttributes = "cute generic creature"
        name = ""
        currentVisualURL = nil
        currentVideoURL = nil
        currentHappyVideoURL = nil
        behaviorPrompt = ""
        personalityPrompt = ""
        learnedSkills = []
        isHappy = false
        isEvolving = false
        energy = 100
        isDead = false
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
    }
}
