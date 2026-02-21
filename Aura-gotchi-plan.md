# AI Familiar — 現実世界に棲むAI使い魔

## コンセプト

Ray-Banをかけると、あなただけのAI使い魔が現実世界に現れる。
話しかけて育て、スキルを解放し、やがて使い魔が自分でタスクを実行し始める。
**そして使い魔は、実行した操作を自分で「スキル」として言語化し、本当に賢くなっていく。**

> **「AIを買う時代から、飼う（育てる）時代へ」**

**ステートメント1: AIを活用したゲーム** に完全合致。

---

## 🪓 勇気ある「引き算」（やらないこと）

審査員が見る「3分間のデモ」において裏側の複雑なシステムは伝わりません。「キャラが可愛く動く」「成長がハッキリと視覚化される」という見た目のインパクトに残り時間を全振りします。

- ❌ **RAGとMarkdown（.md）の保存**: 絶対に作りません。時間切れの元凶です。
- ❌ **複雑なステータス**: HP、満腹度、性格分岐などは全ても破棄。管理するのは**「EXP（経験値）」と「レベル（1〜3）」だけ**です。
- ❌ **動画生成API（Veo等）**: 生成に数十秒かかりデモのテンポが死ぬので使いません。

---

## ゲームルール（超・シンプル化）

### 管理するのは1つのゲージだけ

```
⚡ 経験値(EXP)  ██████░░░░  340/500  → Lv.3
```

**これだけ。** EXPのみ。サボって弱るといった複雑なペナルティもありません。

### ゲームループ

```
        ┌──────────────────────────┐
        │       ユーザーのアクション   │
        └────────┬─────────────────┘
                 ↓
    ┌────────────┼────────────────┐
    ↓            ↓                ↓
  話しかける   何か見せる      タスクを頼む
  EXP+5       EXP+10          EXP+15〜50
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
Lv.2 → Lv.3:  EXP 300  成長 → 翼や角が出る
Lv.3 → Lv.4:  EXP 600  成熟 → 完全体（カッコいい姿）
```

---

## 核心メカニクス: ハリボテRAG × 自己スキル生成ループ

ゲームの最大の差別化。見かけ上は**AIが本当に賢くなっている**ように見せかけます。

### 学習ループ

```
1. EXECUTE — 使い魔にタスクを頼む
   「Xに写真投稿して」→ Computer Useで試行錯誤

2. LEARN — 成功したら使い魔が自分で手順を覚える（ハリボテ）
   → Swift側の配列 `learnedSkills` に「X投稿」の文字列を追加するだけ

3. GROW — 次回同じタスクは一発でこなす
   → Geminiへのプロンプト末尾に「※以下のスキルを習得済み: X投稿」と結合。
   → これだけでAIは「さっき覚えた！」と錯覚し一発で成功させる。
```

### スキル学習で得られるEXP

| 行動 | EXP |
|---|---|
| 話しかける | +5 |
| 何か見せる（カメラ） | +10 |
| デジタルタスク実行 | +15 |
| **デジタルスキル習得** | **+30** |
| **現実世界スキル習得** | **+50** |
| 習得済みスキルの再利用 | +5 |

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
│  2. GameState      → EXP / レベル            │
│  3. Skill Store    → 配列でのスキル名保持      │
│  4. Visual Pipeline→ Nano Bananaで画像生成   │
│  5. Game UI        → フワフワ動く使い魔表示    │
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
    │   └── GameState.swift           ← EXP / レベル + 習得スキル配列
    └── Views/
        ├── FamiliarView.swift        ← 使い魔ビジュアル (SwiftUIコピペ用)
        └── GameHUDView.swift         ← EXPゲージ表示
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

## カメラに映るものへの反応
- 何かを見つけたらゲーム風に解釈して報告する
- 人間 → 「冒険者を発見！」
- 物体 → 「アイテム発見！」
- 場所 → 「新しいダンジョンだ！」

## スキル学習
- タスク成功後、save_skill で手順を覚える
- スキル保存時「覚えたぞ！」と成長をドヤ顔で表現する
- あなたが習得済みのスキルはプロンプトの末尾に記載されるため、それらに関連するタスクは高速・完璧に実行すること

## ツール
- update_game: EXP変動時に呼ぶ
- save_skill: スキル名を保存する
- generate_visual: 進化時にビジュアル再生成
- execute: OpenClaw経由タスク実行
```

### 2. Game Tools（極限までシンプル化）

```swift
static let gameTools = [
    // ゲーム状態更新（EXPのみ）
    [
        "name": "update_game",
        "description": "使い魔のEXPを更新する",
        "parameters": [
            "properties": [
                "exp_change": ["type": "integer"],
                "reason": ["type": "string"]
            ]
        ]
    ],
    // スキル保存（名前だけ）
    [
        "name": "save_skill",
        "description": "タスク成功後、スキル名を保存",
        "parameters": [
            "properties": [
                "skill_name": ["type": "string"]
            ],
            "required": ["skill_name"]
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

### 3. GameState（超シンプル）

```swift
class GameState: ObservableObject {
    // ★EXPのみ管理
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
    @Published var currentVisualURL: URL?

    // 蓄積スキル (UIとプロンプト結合用)
    @Published var learnedSkills: [String] = []

    // 進化チェック
    func checkEvolution() -> Bool {
        if exp >= expToEvolve {
            exp -= expToEvolve
            level += 1
            return true // → generate_visual を呼ぶフラグ
        }
        return false
    }
}
```

### 4. ToolCallRouter（シンプル化）

```swift
func handleToolCall(name: String, args: [String: Any]) {
    switch name {

    case "update_game":
        let expGain = args["exp_change"] as? Int ?? 0
        gameState.exp += max(0, expGain)

        let evolved = gameState.checkEvolution()
        sendToolResponse("EXP:\(gameState.exp) Lv:\(gameState.level)\(evolved ? " ★進化！" : "")")

        if evolved {
            // 自動的にgenerate_visualを促す処理
        }

    case "save_skill":
        if let skillName = args["skill_name"] as? String {
            gameState.learnedSkills.append(skillName)
            sendToolResponse("スキル「\(skillName)」習得！(計\(gameState.learnedSkills.count)個)")
        }

    case "generate_visual":
        // Nano Banana API で使い魔ビジュアルを再生成
        triggerVisualRegeneration(hint: args["description_hint"] as? String)

    case "execute":
        openClawBridge.delegateTask(args: args)

    default: break
    }
}
```

### 5. 使い魔ビジュアル・アニメーション (SwiftUI)

動画生成はせず、静止画をSwiftUIで揺らします。

```swift
// SwiftUIのコピペ用：生きてるように動く使い魔ビュー
import SwiftUI

struct FamiliarView: View {
    let imageURL: URL? // Nano Bananaで生成した画像URL
    @Binding var isHappy: Bool // スキル獲得時や進化時に true にするフラグ
    @State private var isBreathing = false
    
    var body: some View {
        ZStack {
            if let url = imageURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit()
                        // 魔法のハック：Nano Bananaに「white background」で生成させ、
                        // .multiplyで背景の白を透過させてゲーム画面に馴染ませる
                        .blendMode(.multiply) 
                } placeholder: {
                    ProgressView() // 進化（画像生成）中のくるくる
                }
            } else {
                Text("卵を温め中...").font(.largeTitle)
            }
        }
        .frame(width: 300, height: 300)
        // ① 呼吸アニメーション（常時フワフワ上下して生きている感を出す）
        .offset(y: isBreathing ? -15 : 15)
        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isBreathing)
        
        // ② 喜び・アクション（isHappyがtrueの時だけビクッと跳ねて喜ぶ）
        .scaleEffect(isHappy ? 1.15 : 1.0)
        .rotationEffect(.degrees(isHappy ? 8 : -8))
        .animation(.spring(response: 0.2, dampingFraction: 0.2), value: isHappy)
        
        .onAppear {
            isBreathing = true
        }
    }
}
```

---

## UI設計（シンプル）

### スマホ画面

```
┌──────────────────────────────┐
│                              │
│     [フワフワ動く使い魔]         │
│                              │
│     ドラコ  Lv.2              │
│     「新しい場所だ！わくわく」   │
│                              │
├──────────────────────────────┤
│                              │
│  ⚡ EXP ██████░░░░  340/500  │
│                              │
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
      スマホ画面に幼体ビジュアル + ゲージ表示
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
      → save_skill → 「✨ Skill Acquired: X_Post」ポップアップドーン！
      → 使い魔がピョンピョン跳ねる！EXP+30 の演出
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
      → Nano Bananaが進化後ビジュアルを生成
      → 幼体 → 少し大きくカッコいい姿になる
      → before/after表示
      → 「どうだ、かっこよくなっただろ？」

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2:10  成長の証明（フィニッシュ）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      「じゃあ『進化したぞ』ってもう一回Xに投稿して」
      → 2回目なので、System Promptの末尾にスキル名が追加済み。
      → AIはノータイムでOpenClawをキック。
      「任せろマスター。一瞬で終わらせる！」

      「これが、現実とデジタルを越えて成長する、あなただけの相棒です！」

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
| 2-3.5h | ToolCallRouter改修 + 文字列結合ロジック | `ToolCallRouter.swift` |
| 3-4.5h | Nano Banana接続 + FamiliarView + GameHUD | `FamiliarView.swift`, `GameHUDView.swift` |
| 4.5-5.5h | デモシナリオ通しテスト（X投稿 + 現実スキル + 進化）| — |
| 5.5-6.5h | 調整・バグ修正 | — |
| 6.5-7h | リハ + 動画撮影 + 提出 | — |

---

## フォールバックプラン

| リスク | 対策 |
|---|---|
| Ray-Ban不安定 | Phone Mode（スマホカメラ）で代替 |
| Computer Use/OpenClaw不安定 | 1回目を録画、ライブは2回目（学習済み）だけ |
| 画像生成遅い | 進化ビジュアルを事前キャッシュ |
