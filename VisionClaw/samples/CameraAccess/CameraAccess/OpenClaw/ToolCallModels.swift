import Foundation

// MARK: - Gemini Tool Call (parsed from server JSON)

struct GeminiFunctionCall {
  let id: String
  let name: String
  let args: [String: Any]
}

struct GeminiToolCall {
  let functionCalls: [GeminiFunctionCall]

  init?(json: [String: Any]) {
    guard let toolCall = json["toolCall"] as? [String: Any],
          let calls = toolCall["functionCalls"] as? [[String: Any]] else {
      return nil
    }
    self.functionCalls = calls.compactMap { call in
      guard let id = call["id"] as? String,
            let name = call["name"] as? String else { return nil }
      let args = call["args"] as? [String: Any] ?? [:]
      return GeminiFunctionCall(id: id, name: name, args: args)
    }
  }
}

// MARK: - Gemini Tool Call Cancellation

struct GeminiToolCallCancellation {
  let ids: [String]

  init?(json: [String: Any]) {
    guard let cancellation = json["toolCallCancellation"] as? [String: Any],
          let ids = cancellation["ids"] as? [String] else {
      return nil
    }
    self.ids = ids
  }
}

// MARK: - Tool Result

enum ToolResult {
  case success(String)
  case failure(String)

  var responseValue: [String: Any] {
    switch self {
    case .success(let result):
      return ["result": result]
    case .failure(let error):
      return ["error": error]
    }
  }
}

// MARK: - Tool Call Status (for UI)

enum ToolCallStatus: Equatable {
  case idle
  case executing(String)
  case completed(String)
  case failed(String, String)
  case cancelled(String)

  var displayText: String {
    switch self {
    case .idle: return ""
    case .executing(let name): return "Running: \(name)..."
    case .completed(let name): return "Done: \(name)"
    case .failed(let name, let err): return "Failed: \(name) - \(err)"
    case .cancelled(let name): return "Cancelled: \(name)"
    }
  }

  var isActive: Bool {
    if case .executing = self { return true }
    return false
  }
}

// MARK: - Tool Declarations (for Gemini setup message)

enum ToolDeclarations {

  static func allDeclarations() -> [[String: Any]] {
    return [execute, parseDrawing, updateGame, saveSkillTool, generateVisual]
  }

  static let execute: [String: Any] = [
    "name": "execute",
    "description": "外部タスクを実行する。メッセージ送信、Web検索、アプリ操作など、自分でできないことは全てこれを使う。",
    "parameters": [
      "type": "object",
      "properties": [
        "task": [
          "type": "string",
          "description": "実行するタスクの詳細な説明"
        ]
      ],
      "required": ["task"]
    ] as [String: Any],
    "behavior": "BLOCKING"
  ]

  static let parseDrawing: [String: Any] = [
    "name": "parse_drawing",
    "description": "ユーザーが描いた手書きの絵を解析して、使い魔の初期属性と物理的な振る舞いを決定する。ゲーム開始時に一度だけ呼ぶ。",
    "parameters": [
      "type": "object",
      "properties": [
        "attributes": [
          "type": "string",
          "description": "絵から読み取った特徴（例: fire slime, round shape）"
        ],
        "behavior": [
          "type": "string",
          "description": "物理的な振る舞いやエフェクト (例: burns and floats, bounces rapidly, crystallizes)"
        ]
      ],
      "required": ["attributes"]
    ] as [String: Any]
  ]

  static let updateGame: [String: Any] = [
    "name": "update_game",
    "description": "使い魔のEXPとエネルギーを更新する。行動のたびに呼ぶ。",
    "parameters": [
      "type": "object",
      "properties": [
        "exp_change": [
          "type": "integer",
          "description": "経験値の増加量"
        ],
        "energy_change": [
          "type": "integer",
          "description": "エネルギーの変動量（-100〜+100）。画面見すぎ→減少、休息・食事・自然→回復"
        ],
        "reason": [
          "type": "string",
          "description": "更新理由"
        ]
      ]
    ] as [String: Any]
  ]

  static let saveSkillTool: [String: Any] = [
    "name": "save_skill",
    "description": "タスク成功後、スキル名を保存する。",
    "parameters": [
      "type": "object",
      "properties": [
        "skill_name": [
          "type": "string",
          "description": "スキル名（例: X投稿、Web検索）"
        ]
      ],
      "required": ["skill_name"]
    ] as [String: Any]
  ]

  static let generateVisual: [String: Any] = [
    "name": "generate_visual",
    "description": "使い魔のビジュアルを再生成する。進化時や見た目を変えたい時に呼ぶ。",
    "parameters": [
      "type": "object",
      "properties": [
        "description_hint": [
          "type": "string",
          "description": "見た目のヒント（例: evolved fire slime with wings）"
        ]
      ]
    ] as [String: Any]
  ]
}
