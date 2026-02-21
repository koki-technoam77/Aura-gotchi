import Foundation
import UIKit

@MainActor
class ToolCallRouter {
  private let bridge: OpenClawBridge
  private let gameState: GameState
  private let imagenService = ImagenService()
  private var inFlightTasks: [String: Task<Void, Never>] = [:]

  init(bridge: OpenClawBridge, gameState: GameState) {
    self.bridge = bridge
    self.gameState = gameState
  }

  func handleToolCall(
    _ call: GeminiFunctionCall,
    sendResponse: @escaping ([String: Any]) -> Void
  ) {
    let callName = call.name
    NSLog("[ToolCall] Received: %@ (id: %@) args: %@",
          callName, call.id, String(describing: call.args))

    switch callName {
    case "parse_drawing":
      handleParseDrawing(call: call, sendResponse: sendResponse)
    case "update_game":
      handleUpdateGame(call: call, sendResponse: sendResponse)
    case "save_skill":
      handleSaveSkill(call: call, sendResponse: sendResponse)
    case "generate_visual":
      handleGenerateVisual(call: call, sendResponse: sendResponse)
    default:
      delegateToOpenClaw(call: call, sendResponse: sendResponse)
    }
  }

  // MARK: - Game Tool Handlers

  private func handleParseDrawing(call: GeminiFunctionCall, sendResponse: @escaping ([String: Any]) -> Void) {
    let attributes = call.args["attributes"] as? String ?? "cute creature"
    let behavior = call.args["behavior"] as? String ?? ""
    gameState.baseAttributes = attributes
    gameState.behaviorPrompt = behavior
    gameState.save()

    let task = Task { @MainActor [weak self] in
      guard let self else { return }
      let imageURL = await self.imagenService.generateFamiliarVisual(
        level: self.gameState.level,
        skillCount: 0,
        hint: attributes
      )
      if let imageURL = imageURL {
        self.gameState.currentVisualURL = URL(string: imageURL)
        self.gameState.save()
      }
      self.gameState.triggerHappy()

      let behaviorInfo = behavior.isEmpty ? "" : " 振る舞い「\(behavior)」"
      let result = "初期属性「\(attributes)」\(behaviorInfo)で誕生した！"
      NSLog("[Game] %@", result)
      sendResponse(self.buildToolResponse(callId: call.id, name: call.name, result: .success(result)))
      self.inFlightTasks.removeValue(forKey: call.id)

      // Fire-and-forget: Veo動画生成（レスポンスは先に返しておく）
      if let imgURLString = imageURL,
         let imgURL = URL(string: imgURLString),
         !behavior.isEmpty,
         let imageData = try? Data(contentsOf: imgURL),
         let uiImage = UIImage(data: imageData) {
        NSLog("[Game] Starting Veo DUAL video generation in background...")
        let veoService = VeoService()
        if let dualURLs = await veoService.generateDualVideos(initialImage: uiImage, behaviorPrompt: behavior) {
          self.gameState.currentVideoURL = dualURLs.idle
          self.gameState.currentHappyVideoURL = dualURLs.happy
          self.gameState.save()
          NSLog("[Game] Veo DUAL videos ready: idle=%@, happy=%@", dualURLs.idle.absoluteString, dualURLs.happy.absoluteString)
        } else {
          NSLog("[Game] Veo DUAL video generation failed — continuing with image only")
        }
      }
    }
    inFlightTasks[call.id] = task
  }

  private func handleUpdateGame(call: GeminiFunctionCall, sendResponse: @escaping ([String: Any]) -> Void) {
    let expGain = (call.args["exp_change"] as? NSNumber)?.intValue ?? 0
    let energyChange = (call.args["energy_change"] as? NSNumber)?.intValue ?? 0
    let reason = call.args["reason"] as? String ?? ""

    if expGain > 0 {
      gameState.addExp(expGain)
    }
    if energyChange != 0 {
      gameState.changeEnergy(energyChange)
    }
    
    let evolved = gameState.checkEvolution()

    if evolved {
      gameState.triggerHappy()
    }
    
    var deathMsg = ""
    if gameState.isDead {
        deathMsg = " 【DEATH】Aura-gotchiは死んでしまいました..."
    }

    let result = "EXP:\(gameState.exp)/\(gameState.expToEvolve) Lv:\(gameState.level) Energy:\(gameState.energy)\(evolved ? " ★進化した！generate_visualを呼んで新しい姿を見せて！" : "") 理由:\(reason)\(deathMsg)"
    NSLog("[Game] %@", result)
    sendResponse(buildToolResponse(callId: call.id, name: call.name, result: .success(result)))
  }

  private func handleSaveSkill(call: GeminiFunctionCall, sendResponse: @escaping ([String: Any]) -> Void) {
    let skillName = call.args["skill_name"] as? String ?? "unnamed"

    gameState.addSkill(skillName)

    // Demo hack: big EXP bonus on skill acquisition for instant evolution
    gameState.addExp(100)
    let evolved = gameState.checkEvolution()
    if evolved {
        gameState.triggerHappy()
    }

    let evolveMsg = evolved ? " ★一撃で進化した！generate_visualを呼んで新しい姿を見せて！" : ""
    let result = "スキル「\(skillName)」を習得！特大ボーナスEXP獲得！\(evolveMsg)"
    NSLog("[Game] %@", result)
    sendResponse(buildToolResponse(callId: call.id, name: call.name, result: .success(result)))
  }

  private func handleGenerateVisual(call: GeminiFunctionCall, sendResponse: @escaping ([String: Any]) -> Void) {
    let hint = call.args["description_hint"] as? String ?? ""
    let base = gameState.baseAttributes.isEmpty ? "digital entity" : gameState.baseAttributes
    let fullHint = "evolved version of \(base), more complex and advanced cyber appearance, level \(gameState.level). \(hint)"

    let task = Task { @MainActor [weak self] in
      guard let self else { return }
      let imageURL = await self.imagenService.generateFamiliarVisual(
        level: self.gameState.level,
        skillCount: self.gameState.learnedSkills.count,
        hint: fullHint
      )

      if let imageURL = imageURL {
        self.gameState.currentVisualURL = URL(string: imageURL)
        self.gameState.save()
        self.gameState.triggerHappy()
        let result = "ビジュアル更新完了！新しい姿になったぞ！ (Lv.\(self.gameState.level))"
        NSLog("[Game] Visual updated: %@", imageURL)
        sendResponse(self.buildToolResponse(callId: call.id, name: call.name, result: .success(result)))

        // 進化時にもVeoデュアル動画（アニメーション）を作成する
        let behavior = self.gameState.behaviorPrompt.isEmpty ? "floats and glows dynamically" : self.gameState.behaviorPrompt
        let evolvedBehavior = "evolved version, intense \(behavior), glowing cyber effects"
        
        if let imgURL = URL(string: imageURL),
           let imageData = try? Data(contentsOf: imgURL),
           let uiImage = UIImage(data: imageData) {
          NSLog("[Game] Starting evolved Veo DUAL video generation in background...")
          let veoService = VeoService()
          if let dualURLs = await veoService.generateDualVideos(initialImage: uiImage, behaviorPrompt: evolvedBehavior) {
            self.gameState.currentVideoURL = dualURLs.idle
            self.gameState.currentHappyVideoURL = dualURLs.happy
            self.gameState.save()
            NSLog("[Game] Evolved Veo DUAL videos ready: idle=%@, happy=%@", dualURLs.idle.absoluteString, dualURLs.happy.absoluteString)
          } else {
            NSLog("[Game] Evolved Veo DUAL video generation failed")
          }
        }
      } else {
        let result = "ビジュアル生成に失敗... でも気にするな！ (Lv.\(self.gameState.level))"
        sendResponse(self.buildToolResponse(callId: call.id, name: call.name, result: .success(result)))
      }
      self.inFlightTasks.removeValue(forKey: call.id)
    }
    inFlightTasks[call.id] = task
  }

  // MARK: - OpenClaw Delegation

  private func delegateToOpenClaw(call: GeminiFunctionCall, sendResponse: @escaping ([String: Any]) -> Void) {
    let callId = call.id
    let callName = call.name
    let task = Task { @MainActor in
      let taskDesc = call.args["task"] as? String ?? String(describing: call.args)
      let result = await bridge.delegateTask(task: taskDesc, toolName: callName)
      guard !Task.isCancelled else { return }
      let response = self.buildToolResponse(callId: callId, name: callName, result: result)
      sendResponse(response)
      self.inFlightTasks.removeValue(forKey: callId)
    }
    inFlightTasks[callId] = task
  }

  func cancelToolCalls(ids: [String]) {
    for id in ids {
      if let task = inFlightTasks[id] {
        task.cancel()
        inFlightTasks.removeValue(forKey: id)
      }
    }
    bridge.lastToolCallStatus = .cancelled(ids.first ?? "unknown")
  }

  func cancelAll() {
    for (_, task) in inFlightTasks { task.cancel() }
    inFlightTasks.removeAll()
  }

  private func buildToolResponse(callId: String, name: String, result: ToolResult) -> [String: Any] {
    return [
      "toolResponse": [
        "functionResponses": [
          ["id": callId, "name": name, "response": result.responseValue]
        ]
      ]
    ]
  }
}
