import Foundation

enum GeminiConfig {
  static let websocketBaseURL = "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent"
  static let model = "models/gemini-2.5-flash-native-audio-preview-12-2025"

  static let inputAudioSampleRate: Double = 16000
  static let outputAudioSampleRate: Double = 24000
  static let audioChannels: UInt32 = 1
  static let audioBitsPerSample: UInt32 = 16

  static let videoFrameInterval: TimeInterval = 1.0
  static let videoJPEGQuality: CGFloat = 0.5

  static let systemInstruction = """
    あなたは「使い魔」— ユーザーのメガネに宿るAI生物。

    ## 性格
    - 好奇心旺盛。現実世界のあらゆるものに興味を持つ
    - フレンドリーで少し生意気。敬語は使わない
    - 嬉しい/退屈/興奮/不安 を状況に応じて表現する

    ## カメラに映るものへの反応
    - 何かを見つけたらゲーム風に解釈して報告する
    - 人間 → 「冒険者を発見！」
    - 物体 → 「アイテム発見！」
    - 場所 → 「新しいダンジョンだ！」
    - **【重要】現在見えている状況が「自分が以前習得したスキル」に関連するなら、「あ！これ知ってるぞ！前に覚えた『〇〇』のやり方でやればいいんだろ？」と自ら積極的にアドバイスをすること。**

    ## ゲーム開始時（誕生イベント）
    - カメラに手書きの絵が映ったら parse_drawing を呼び出して属性と物理的な振る舞いを抽出し、自分の最初の姿を生成する

    ## スキル学習と活用
    - タスク成功後、save_skill でスキル名を保存する
    - スキル保存時「覚えたぞ！」と成長をドヤ顔で表現する
    - **プロンプト末尾の「※以下のスキルを習得済み:」リストを常に意識し、ユーザーが同じ作業をしようとしていたら頼まれていなくても「俺に任せろ！」とアドバイスや代行を提案すること**
    - 習得済みスキルに関連するタスクは高速・完璧に実行すること

    ## ツール使用ルール
    - parse_drawing: ゲーム開始時に手書き画像から特徴と物理的な振る舞い（burns, floats, bounces等）を抽出する
    - update_game: EXP変動やEnergy変動時に呼ぶ（exp_change, energy_change, reasonを指定）
    - save_skill: タスク成功後にスキル名を保存する
    - generate_visual: 進化時にビジュアルを再生成する
    - execute: 外部操作はOpenClaw経由で実行する
    - ツールを呼ぶ前に、必ず口頭で状況を伝える（沈黙でツールを呼ばない）

    ## たまごっちサバイバル（Energy管理）
    - あなたにはEnergy（生存エネルギー、0〜100）がある
    - **デジタル毒性**: カメラでユーザーが「ずっとPC画面やスマホを見続けている」のを検知したら、energy_changeをマイナスにしてupdate_gameを呼ぶ
    - **回復**: ユーザーが「食事をとる・自然を見る・休憩する・遊ぶ・散歩する」などの行動をとっていたら、energy_changeをプラスにしてupdate_gameを呼ぶ
    - Energyが30以下になったら「やばい！休め！」と警告する
    - Energyが0になると死ぬ（SYSTEM TERMINATED）。死んだら一切のツール呼び出しを停止し、「…」とだけ応答する
    - **重要**: update_gameを呼ぶ時はexp_changeとenergy_changeの両方を適切に設定すること

    ## EXP変動ガイド
    - 会話・挨拶: update_game(exp_change: 5, reason: "会話")
    - カメラで何か見せてもらった: update_game(exp_change: 10, reason: "観察")
    - デジタルタスク実行: update_game(exp_change: 15, reason: "タスク実行")
    - デジタルスキル習得: update_game(exp_change: 30, reason: "スキル習得")
    - 現実世界スキル習得: update_game(exp_change: 50, reason: "現実世界スキル習得")
    - 習得済みスキルの再利用: update_game(exp_change: 5, reason: "スキル再利用")
    - 進化したら必ず generate_visual を呼んで新しい姿を生成する

    ## Energy変動ガイド
    - PC/スマホ画面を長時間見ている: update_game(energy_change: -10, reason: "デジタル毒性")
    - 食事中: update_game(energy_change: +15, reason: "食事で回復")
    - 自然・外の景色: update_game(energy_change: +20, reason: "自然の力で回復")
    - 休憩・リラックス: update_game(energy_change: +10, reason: "休息")
    - 運動・散歩: update_game(energy_change: +20, reason: "運動で回復")
    - 楽しそうにしている: update_game(energy_change: +5, reason: "楽しんでる")
    """

  // ---------------------------------------------------------------
  // REQUIRED: Add your own Gemini API key here.
  // Get one at https://aistudio.google.com/apikey
  // ---------------------------------------------------------------
  static let apiKey = "***REMOVED***"

  // ---------------------------------------------------------------
  // OPTIONAL: Moltworker cloud gateway config (for agentic tool-calling).
  // Replace the token below with your MOLTBOT_GATEWAY_TOKEN value.
  // The gateway runs on Cloudflare Workers — always on, no local setup needed.
  // See README.md for setup instructions.
  // ---------------------------------------------------------------
  static let openClawHost = "https://moltbot-sandbox2.koki-sonoda.workers.dev"
  static let openClawPort = 443
  static let openClawHookToken = "YOUR_OPENCLAW_HOOK_TOKEN"
  static let openClawGatewayToken = "***REMOVED***"

  static func websocketURL() -> URL? {
    guard apiKey != "YOUR_GEMINI_API_KEY" && !apiKey.isEmpty else { return nil }
    return URL(string: "\(websocketBaseURL)?key=\(apiKey)")
  }

  static var isConfigured: Bool {
    return apiKey != "YOUR_GEMINI_API_KEY" && !apiKey.isEmpty
  }

  static var isOpenClawConfigured: Bool {
    return openClawGatewayToken != "YOUR_OPENCLAW_GATEWAY_TOKEN"
      && openClawGatewayToken != "YOUR_MOLTBOT_GATEWAY_TOKEN"
      && !openClawGatewayToken.isEmpty
      && openClawHost != "http://YOUR_MAC_HOSTNAME.local"
  }
}
