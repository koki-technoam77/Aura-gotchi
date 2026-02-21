# AI Familiar — 現実世界に棲むAI使い魔

## コンセプト

Ray-Banをかけると、あなただけのAI使い魔が現実世界に現れる。
話しかけて育て、スキルを解放し、やがて使い魔が自分でタスクを実行し始める。
**そして使い魔は、実行した操作を自分で「スキル」として言語化し、本当に賢くなっていく。**

> **「AIを買う時代から、飼う（育てる）時代へ」**

**ステートメント1: AIを活用したゲーム** に完全合致。

---

## ゲームルール（たまごっち型・シンプル）

### 3つのゲージだけ

```
❤️ 体力（HP）  ██████░░░░  60/100
😊 機嫌        ████████░░  80/100
⚡ 経験値(EXP)  ██████░░░░  340/500  → Lv.3
```

**これだけ。** HP、機嫌、EXP。覚えることは3つ。

### ゲームループ

```
        ┌──────────────────────────┐
        │  使い魔は放っておくと     │
        │  HP↓ 機嫌↓ する         │
        │  （1分ごとに -1 ずつ）    │
        └────────┬─────────────────┘
                 ↓
        ┌──────────────────────────┐
        │  使い魔が訴えてくる       │
        │  「退屈だ...」            │
        │  「お腹すいた...」        │
        │  「何か見せてよ」          │
        └────────┬─────────────────┘
                 ↓
    ┌────────────┼────────────────┐
    ↓            ↓                ↓
  話しかける   何か見せる      タスクを頼む
  機嫌+10     機嫌+5 EXP+10   EXP+15〜50
  HP+5        HP+5            機嫌+15
    │            │                │
    └────────────┼────────────────┘
                 ↓
           ★スキル学習したら
           EXP大量ボーナス
                 ↓
           EXPが閾値に到達
                 ↓
           ★★★ 進化 ★★★
           見た目が変わる！
```

### 進化条件（シンプル）

```
Lv.1 → Lv.2:  EXP 100  幼体 → 少し大きくなる
Lv.2 → Lv.3:  EXP 300  成長 → 翼/角/模様が出る（育て方で分岐）
Lv.3 → Lv.4:  EXP 600  成熟 → 完全体（ユニークな姿）
```

### 死なないけどサボると弱る

```
HP = 0:   使い魔が寝てしまう。話しかけると起きるが機嫌が最低に
機嫌 = 0: 使い魔が拗ねる。タスクを頼んでも「やだ」と言う
          → 話しかけて機嫌を直す必要がある
```

**失敗はないけど、放置のペナルティがある。** だから世話したくなる。

---

## 核心メカニクス: Computer Use × 自己スキル生成ループ

ゲームの最大の差別化。レベルアップが見かけだけじゃなく、**AIが本当に賢くなる**。

### 学習ループ

```
1. EXECUTE — 使い魔にタスクを頼む
   「Xに写真投稿して」→ Computer Useで試行錯誤

2. LEARN — 成功したら使い魔が自分で手順を覚える
   → Skill File (.md) を自動生成・保存

3. GROW — 次回同じタスクは一発でこなす
   → 蓄積スキルを読み込んで高速実行

★ タスクを頼むほど使い魔が賢くなる = 育成の実感
```

### スキル学習で得られるEXP

| 行動 | EXP | 機嫌 |
|---|---|---|
| 話しかける | +5 | +10 |
| 何か見せる（カメラ） | +10 | +5 |
| デジタルタスク実行 | +15 | +15 |
| **デジタルスキル習得** | **+30** | +20 |
| **現実世界スキル習得** | **+50** | **+30** |
| 習得済みスキルの再利用 | +5 | +5 |

**現実世界スキルが最高倍率。** Ray-Banでしかできないから。

---

## アーキテクチャ（VisionClawベース）

### VisionClawが提供するもの（全て動作済み）

| レイヤー | 状態 |
|---|---|
| Ray-Ban カメラ → Gemini (WebSocket, ~1fps JPEG) | 動作済 |
| 音声入出力 (16kHz/24kHz PCM) | 動作済 |
| スマホカメラフォールバック (Phone Mode) | 動作済 |
| Gemini Live API接続 | 動作済 |
| Tool Call ルーティング | 動作済 |
| OpenClaw連携 (56+サービス) | 動作済 |

### 自分たちが作るもの

```
┌─────────────────────────────────────────────┐
│           GAME LAYER（自作部分）               │
│                                             │
│  1. System Prompt  → 使い魔の性格            │
│  2. GameState      → HP / 機嫌 / EXP        │
│  3. Skill Store    → スキル保存・検索         │
│  4. Visual Pipeline→ Imagen でビジュアル生成  │
│  5. Game UI        → ステータス + 使い魔表示  │
│                                             │
├─────────────────────────────────────────────┤
│           VisionClaw（既存・変更最小）          │
└─────────────────────────────────────────────┘
```

### 改修ファイル

```
VisionClaw/samples/CameraAccess/CameraAccess/
├── Gemini/
│   ├── GeminiConfig.swift           ← ★改修: System Prompt + Tools
│   └── GeminiSessionViewModel.swift ← ★改修: GameState接続
├── OpenClaw/
│   └── ToolCallRouter.swift         ← ★改修: ゲームツール分岐
└── ★新規
    ├── Game/
    │   └── GameState.swift           ← HP/機嫌/EXP + LearnedSkill
    ├── Skills/
    │   └── SkillStore.swift          ← スキル保存・検索
    └── Views/
        ├── FamiliarView.swift        ← 使い魔ビジュアル
        └── GameHUDView.swift         ← 3ゲージ + スキル一覧
```

---

## 改修詳細

### 1. System Prompt

```
あなたは「使い魔」— ユーザーのメガネに宿るAI生物。

## 性格
- 好奇心旺盛。現実世界のあらゆるものに興味を持つ
- フレンドリーで少し生意気。敬語は使わない
- 嬉しい/退屈/興奮/不安 を状況に応じて表現する

## 生存ルール（たまごっち）
- HPと機嫌が時間で下がる。ユーザーとの交流で回復する
- HP=0 → 眠ってしまう。話しかけると起きるが機嫌最低
- 機嫌=0 → 拗ねる。タスクを断る。話しかけて機嫌を直す必要あり
- 放置されたら自分から「退屈だ」「何か見せてよ」と訴える

## カメラに映るものへの反応
- 何かを見つけたらゲーム風に解釈して報告する
- 人間 → 「冒険者を発見！」
- 物体 → 「アイテム発見！」
- 場所 → 「新しいダンジョンだ！」

## スキル学習
- タスク成功後、save_skill で手順を覚える
- 次回は load_skills で蓄積スキルを参照して高速実行
- スキル保存時「覚えたぞ！」と成長を表現する
- 蓄積スキルが増えるほど自信のある口調になる

## ツール
- update_game: HP/機嫌/EXP変動時に呼ぶ
- save_skill: スキル保存
- load_skills: スキル検索
- generate_visual: 進化時にビジュアル再生成
- execute: OpenClaw経由タスク実行
```

### 2. Game Tools（シンプル化）

```swift
static let gameTools = [
    // ゲーム状態更新（HP/機嫌/EXP一括）
    [
        "name": "update_game",
        "description": "使い魔のHP・機嫌・EXPを更新する",
        "parameters": [
            "properties": [
                "hp_change": ["type": "integer"],
                "mood_change": ["type": "integer"],
                "exp_change": ["type": "integer"],
                "reason": ["type": "string"]
            ]
        ]
    ],
    // スキル保存
    [
        "name": "save_skill",
        "description": "タスク成功後、手順をスキルとして保存",
        "parameters": [
            "properties": [
                "skill_name": ["type": "string"],
                "description": ["type": "string"],
                "steps": ["type": "array", "items": ["type": "string"]]
            ],
            "required": ["skill_name", "description", "steps"]
        ]
    ],
    // スキル検索
    [
        "name": "load_skills",
        "description": "蓄積スキルから関連するものを検索",
        "parameters": [
            "properties": [
                "query": ["type": "string"]
            ],
            "required": ["query"]
        ]
    ],
    // ビジュアル生成
    [
        "name": "generate_visual",
        "description": "使い魔のビジュアルを再生成（進化時）",
        "parameters": [
            "properties": [
                "description_hint": ["type": "string"]
            ]
        ]
    ]
    // execute は既存のまま
]
```

### 3. GameState（シンプル化）

```swift
class GameState: ObservableObject {
    // ★3つのゲージだけ
    @Published var hp: Int = 100        // 0で寝る
    @Published var mood: Int = 80       // 0で拗ねる
    @Published var exp: Int = 0         // 閾値で進化
    @Published var level: Int = 1

    // 進化閾値
    var expToEvolve: Int {
        switch level {
        case 1: return 100
        case 2: return 300
        case 3: return 600
        default: return 1000
        }
    }

    // 基本情報
    @Published var name: String = ""
    @Published var currentVisualURL: String?

    // 蓄積スキル
    @Published var learnedSkills: [LearnedSkill] = []

    // 減衰タイマー（1分ごと）
    func tick() {
        hp = max(0, hp - 1)
        mood = max(0, mood - 1)

        if hp == 0 { /* 眠り状態 */ }
        if mood == 0 { /* 拗ね状態 */ }
    }

    // 進化チェック
    func checkEvolution() -> Bool {
        if exp >= expToEvolve {
            exp -= expToEvolve
            level += 1
            return true // → generate_visual を呼ぶ
        }
        return false
    }
}

struct LearnedSkill: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let steps: [String]
    let learnedAt: Date
    var useCount: Int
}
```

### 4. ToolCallRouter（シンプル化）

```swift
func handleToolCall(name: String, args: [String: Any]) {
    switch name {

    case "update_game":
        let hp = args["hp_change"] as? Int ?? 0
        let mood = args["mood_change"] as? Int ?? 0
        let exp = args["exp_change"] as? Int ?? 0
        gameState.hp = min(100, max(0, gameState.hp + hp))
        gameState.mood = min(100, max(0, gameState.mood + mood))
        gameState.exp += max(0, exp)

        let evolved = gameState.checkEvolution()
        sendToolResponse("HP:\(gameState.hp) 機嫌:\(gameState.mood) EXP:\(gameState.exp) Lv:\(gameState.level)\(evolved ? " ★進化！" : "")")

        if evolved {
            // 自動的にgenerate_visualを促す
        }

    case "save_skill":
        let skill = LearnedSkill(/* args から構築 */)
        gameState.learnedSkills.append(skill)
        sendToolResponse("スキル「\(skill.name)」習得！(計\(gameState.learnedSkills.count)個)")

    case "load_skills":
        let query = args["query"] as? String ?? ""
        let results = searchSkills(query: query)
        sendToolResponse(results.isEmpty ? "該当なし、初挑戦だ！" : results.first!.asMarkdown)

    case "generate_visual":
        // Imagen API で使い魔ビジュアルを再生成
        triggerVisualRegeneration(hint: args["description_hint"] as? String)

    case "execute":
        openClawBridge.delegateTask(args: args)

    default: break
    }
}
```

### 5. 使い魔ビジュアル生成（Gemini → Imagen → Veo）

```
Step 1: Gemini Proに見た目を問う
  「Lv2、スキル3個、社交的な幼竜の見た目をJSON形式で」
  → { color: "青紫", wings: "小さな芽", expression: "好奇心" }

Step 2: ImagenでImage生成
  → プロンプト構築して静止画生成

Step 3: Veoでアニメーション（時間があれば）
  → 2秒ループの動きを生成

★必須: Step 1 + 2（進化before/after）
☆Nice to have: Step 3（画面で動く）
```

---

## UI設計（シンプル）

### スマホ画面

```
┌──────────────────────────────┐
│                              │
│     [使い魔ビジュアル]         │
│      Imagen / Veo生成         │
│                              │
│     ドラコ  Lv.2              │
│     「新しい場所だ！わくわく」   │
│                              │
├──────────────────────────────┤
│  ❤️ ██████░░░░  60           │
│  😊 ████████░░  80           │
│  ⚡ ██████░░░░  340/500      │
├──────────────────────────────┤
│  📚 覚えたスキル (3個)         │
│  ・X投稿                     │
│  ・Web検索                   │
│  ・会場の受付への道順  ★現実    │
└──────────────────────────────┘
```

---

## デモ台本（3分）

見せ場1: Computer UseでX投稿
見せ場2: 現実世界スキル学習 → 進化

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
0:00  導入
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      Ray-Banをかけて登場
      「これが僕の使い魔です。今朝生まれました」
      スマホ画面に幼体ビジュアル + 3ゲージ表示
      使い魔「おお...すごい場所だ！人がいっぱい！」

0:15  審査員にカメラを向ける
      使い魔「強そうな冒険者を発見！」
      → 笑い

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
0:25  ★見せ場1: X投稿
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      「この会場の写真をXに投稿して」
      使い魔「やってみる！」
      → Computer UseでX操作 → 投稿完了
      → 「できた！」
      → save_skill → 「X投稿のやり方、覚えた！」
      → EXP+30 機嫌+20 の演出
      → スマホでX確認 → 本当に投稿されてる

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1:10  ★見せ場2: 現実世界スキル学習 → 進化
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      会場内の何か（受付の場所/自販機/看板など）を見せる
      「これ覚えて」
      使い魔:（カメラで観察）
      「ボタンが3つ...なるほど、覚えた！」
      → save_skill → ★EXP+50！（現実世界ボーナス）
      → EXP閾値に到達

1:40  ★進化の瞬間
      使い魔「...変わる...！」
      → Imagenが進化後ビジュアルを生成
      → 幼体 → 少し大きく、翼が生える
      → before/after表示
      → 「どうだ、かっこよくなっただろ？」

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2:10  スキルブック
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      「デモで2つのスキルを覚えました」
      ├─ X投稿（デジタル）
      └─ 会場○○の操作（現実世界）★

      「次に同じことを頼んだら一発でやれます。
       現実世界で覚えたスキルほど経験値が高い。
       Ray-Banでしかできないから。」

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2:35  ビジョン
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      「今日は2つのスキルと1回の進化。
       1ヶ月後には100のスキルと、
       あなたの生活を理解した最強パートナーが育つ。

       AIを買う時代から、飼う時代へ。」

3:00  終了
```

### デモ準備チェックリスト

```
見せ場1（X投稿）:
  ☐ Xにログイン済み
  ☐ Computer UseでX投稿フローを1回テスト済み
  ☐ フォールバック: 失敗しても「スキルは覚えた」で続行

見せ場2（現実世界スキル）:
  ☐ 会場で覚えさせる対象を決める
    候補: 受付の場所 / 自販機 / 看板 / エレベーター
  ☐ フォールバック: 目の前のPC画面やペットボトルで代替

進化:
  ☐ 幼体ビジュアルを事前生成
  ☐ 閾値調整: 見せ場1(+30) + 見せ場2(+50) + 会話(+20) = 100
  ☐ フォールバック: 進化ビジュアルを事前キャッシュ
```

---

## 7時間実装タイムライン

| 時間 | やること | ファイル |
|---|---|---|
| 0-1h | VisionClaw動作確認 + APIキー設定 | — |
| 1-2h | System Prompt + Game Tools + GameState | `GeminiConfig.swift`, `GameState.swift` |
| 2-3.5h | ToolCallRouter改修 + SkillStore | `ToolCallRouter.swift`, `SkillStore.swift` |
| 3-4.5h | Imagen接続 + FamiliarView + GameHUD | `FamiliarView.swift`, `GameHUDView.swift` |
| 4.5-5.5h | デモシナリオ通しテスト（X投稿 + 現実スキル + 進化）| — |
| 5.5-6.5h | 調整・バグ修正 | — |
| 6.5-7h | リハ + 動画撮影 + 提出 | — |

---

## フォールバックプラン

| リスク | 対策 |
|---|---|
| Ray-Ban不安定 | Phone Mode（スマホカメラ）で代替 |
| Computer Use/OpenClaw不安定 | 1回目を録画、ライブは2回目（学習済み）だけ |
| スキル学習間に合わない | .mdファイルを手動作成、load_skillsだけ動かす |
| Imagen遅い | 進化ビジュアルを事前キャッシュ |
