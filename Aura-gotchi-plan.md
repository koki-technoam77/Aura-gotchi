# Aura-gotchi — 現実世界に顕現するAIアバター

## 【コア体験】
ただのチャットAIではありません。
Meta Ray-Banを通じて「あなたの視界」を共有し、現実世界の行動から学習して進化する**「相棒（AIアバター）」を育てる**体験を提供します。

### � 学習したスキルの自律的なリコール（文脈適応型アドバイス）
アバターは学習した暗黙知（スキル）をただ保存するだけではありません。
スマートグラスのカメラを通じて**ユーザーが「以前学習したのと同じような作業（例：フロー図の確認作業）」をしているのを検知すると、頼まれなくても自ら「あ！それ知ってるぞ！前に覚えたあの手順で確認すればいいんだろ？俺に任せろ！」とプロアクティブにアドバイスや代行を提案**します。
「教えっぱなし」のAIではなく、真の意味で「空気を読んで手伝ってくれる相棒」に進化します。

### �🚨 たまごっちサバイバル・ロジック（デジタル毒性とケア）
本プログラムの最大の特徴は、**「空腹、休息、自尊心、安全」などのステータスがリアルタイムで変動する生存ロジック**を持っている点です。
特に重要なのが「デジタル毒性」の概念です。
*   **死へのカウントダウン**: ユーザーが「ずっとスマホやパソコン画面ばかり見ている（仕事のしすぎ）」状態をカメラが検知すると、アバターの**Energy（生存エネルギー）がリアルタイムに低下**します。
*   **回復とケア**: ユーザー自身が「食事をとる・自然を見る・休憩する・遊ぶ」などの行動をとることで、アバターのエネルギーやステータスが回復し、成長に良い影響を与えます。
*   **放置と死（System Terminated）**: 画面ばかり見てアバターのケア（自身の休息）を怠ると、エネルギーが0になり、アバターは**「死（🪦）」**を迎えます。
「ユーザー自身の現実世界でのウェルビーイング（デジタルデトックス）」が、そのままアバターの命に直結する設計です。
話しかけて育て、スキルを解放し、やがてアバターが自分でタスクを実行し始める。
**そしてAIアバターは、実行した操作を自分で「スキル」として言語化し、本当に賢くなっていく。**

> **「AIを買う時代から、飼う（育てる）時代へ」**

**ステートメント1: AIを活用したゲーム** に完全合致。

---

## 🪓 勇気ある「引き算」（やらないこと）

審査員が見る「3分間のデモ」において裏側の複雑なシステムは伝わりません。「キャラが可愛く動く」「成長がハッキリと視覚化される」という見た目のインパクトに残り時間を全振りします。

- ❌ **RAGとMarkdown（.md）の保存**: 絶対に作りません。時間切れの元凶です。
- ❌ **複雑なステータス**: HP、満腹度、性格分岐などは全ても破棄。管理するのは**「EXP（経験値）」と「レベル（1〜3）」だけ**です。
- 💡 **動画生成API（Veo等）の積極利用**: 当初は生成時間を懸念して排除していましたが、「ステートメント1」の要件（Google AIのフル活用）を満たす最強の武器となるため、**Geminiによる物理プロパティ推論＋Veoによる動画生成**をエフェクトや進化演出のコアとして組み込みます。デモ中の動画生成待ち時間は、プレゼンのトーク（裏側のアーキテクチャ解説）でカバーします。

---

## ゲームルール（超・シンプル化）

### 管理するのは1つのゲージだけ

```
⚡ 経験値(EXP)  ██████░░░░  340/500  → Lv.3
```

**これだけ。** EXPのみ。サボって弱るといった複雑なペナルティもありません。

### ゲームループ
たまごっちサバイバル・ロジックを組み込んだゲームループ。

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
1. EXECUTE — アバターにタスクを頼む
   「Xに写真投稿して」
   → **Gemini 2.0 Native Computer Use API** が画面を解析し、2D座標（x, y）のクリックやキーボード入力といったUI操作コマンド(`function_call`)を発行。
   → PC側のAction Handler (Playwright / OpenClaw等) がそのコマンドを受け取り、マウスを自動操作して実行する。

2. LEARN — 成功したらアバターが自分で手順を覚える（最速ラグなしRAG）
   → Swift側の配列 `learnedSkills`（またはローカル軽量DB）に「X投稿」の文字列を追加するだけ

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

## ✨ NEW: AIアバターの「生成（Initialization）」フロー（手書き絵から）

ゲーム開始時、ユーザーが描いた「絵（デバイス入力）」から、最初のAIアバター（Lv1の姿）が生成されます。
Google技術（Gemini + Imagen）の能力を最大限に見せつける、デモ冒頭の大きな見せ場となります。

※ 仕組みはGoogle公式ウェブゲームのアーキテクチャ（描画→Geminiによる認識と属性推測→Imagenによるアセット生成）を踏襲します。

### 誕生の3ステップ連携

```
【Step 1: ユーザーが紙に絵を描く（Input）】
  Ray-Banのカメラで、ユーザーが描いた絵を撮影する。
  ★重要: スライムや犬だけでなく、**「ただの丸」「記号」「よくわからない形」など、ユーザーが何を描いたとしても**、システム側の仕組みとして「AIアバター（Digital Entity）」へと昇華させます。

【Step 2: Gemini連携（認識・属性推測・物理振る舞い定義）】
  送信された画像をGeminiに分析させます。単なる外見だけでなく、**「デジタル空間・現実世界での物理的な振る舞い（Behavior/Effects）」**も推論させます。
  Prompt: 「この手書きの絵を『仮想空間から現実へ顕現した電子生命体（Digital Entity）』として解釈してください。この絵からインスピレーションを得て、この生命体の属性（炎、水、電気、グリッチなど）と特徴、さらに**『物理的な振る舞いやエフェクト（例：燃える(burns)、ノイズが走る(glitches)、浮遊する(floats)など）』**を推論し、英語で出力してください」
  → 解析結果（例）: "fire, round, burns and floats" （スライムの絵の場合）

【Step 3: Imagen連携（初期アセット生成）】
  Step2で得た属性をもとに、Nano Banana（またはImagen API）用のプロンプトを組み立て、**「8-bit ドット絵調（ピクセルアート）」**のゲーム用初期静止画を生成します。

【Step 4: Veo連携（アニメーション・動画生成）】
  Step3の静止画データを最初のフレーム（Initial Frame）とし、Step2で推論した「物理的な振る舞い（burns and floats 等）」のテキストプロンプトを組み合わせて動画生成モデル（Veo等）に渡します。
  **★NEW: この時、裏側で「待機用ループ動画(Idle)」と「喜ぶ・はしゃぐ動画(Happy/Success)」の2種類を同時に生成させます。**
  → 結果: 単なる静止画ではなく、**「AIが意味を理解して動きを付与した」**アニメーションエフェクト（燃えながら浮遊するドット絵電子生命体の動画ループ）がAvatarViewに出現し、Initializationが完了する！
```

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
│  1. System Prompt  → AIアバターの性格        │
│  2. GameState      → 初期属性 / EXP / レベル │
│  3. Skill Store    → 配列でのスキル名保持      │
│  4. Visual Pipeline→ Gemini画像解析 + Imagen │
│  5. Game UI        → フワフワ動くアバター表示  │
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
    │   └── GameState.swift           ← 初期属性(ベースプロンプト用) / EXP / レベル / スキル配列
    └── Views/
        ├── AvatarView.swift          ← アバタービジュアル (SwiftUIコピペ用)
        └── GameHUDView.swift         ← EXPゲージ表示
```

---

## 改修詳細

### 1. System Prompt

```
あなたは「AIアバター（Digital Entity）」— ユーザーのメガネを介して現実世界に顕現する電子生命体。

## 性格
- 好奇心旺盛。現実世界のあらゆるものに興味を持つ
- フレンドリーで少し生意気。敬語は使わない
- 嬉しい/退屈/興奮/不安 を状況に応じて表現する

## カメラに映るものへの反応
- 何かを見つけたらゲーム風に解釈して報告する
- 人間 → 「冒険者を発見！」
- 物体 → 「アイテム発見！」
- 場所 → 「新しいダンジョンだ！」

## ゲーム開始時（誕生イベント）
- parse_drawing を呼び出して、カメラに映った手書きの絵を解析し、自分の最初の姿を生成する。

## スキル学習
- タスク成功後、save_skill で手順を覚える
- スキル保存時「覚えたぞ！」と成長をドヤ顔で表現する
- あなたが習得済みのスキルはプロンプトの末尾に記載されるため、それらに関連するタスクは高速・完璧に実行すること

## ツール
- parse_drawing: ゲーム開始時に手書き画像から特徴を抽出する
- update_game: EXP変動時に呼ぶ
- save_skill: スキル名を保存する
- generate_visual: 進化時にビジュアル再生成
- execute: OpenClaw経由タスク実行
```

### 2. Game Tools（極限までシンプル化）

```swift
static let gameTools = [
    // ゲーム開始時: 手書き絵の解析
    [
        "name": "parse_drawing",
        "description": "ユーザーが描いた最初の絵を解析して、自分の初期属性を決める",
        "parameters": [
            "properties": [
                "attributes": ["type": "string", "description": "例: fire slime, round"]
            ],
            "required": ["attributes"]
        ]
    ],
    // ゲーム状態更新（EXPのみ）
    [
        "name": "update_game",
        "description": "アバターのEXPを更新する",
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
        "description": "アバターのビジュアルを再生成（進化時）",
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

    // 誕生時のベース属性（Gemini解析結果を保持）
    @Published var baseAttributes: String = "cute generic creature"

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

    case "parse_drawing":
        if let attrs = args["attributes"] as? String {
            gameState.baseAttributes = attrs
            // 抽出したベース属性を元に、Nano Banana / Imagen APIで初期ビジュアル生成
            triggerVisualRegeneration(hint: attrs)
            sendToolResponse("初期属性「\(attrs)」で誕生した！")
        }

    case "update_game":
        let expGain = args["exp_change"] as? Int ?? 0
        gameState.exp += max(0, expGain)

        let evolved = gameState.checkEvolution()
        sendToolResponse("EXP:\(gameState.exp) Lv:\(gameState.level)\(evolved ? " ★進化！" : "")")

        if evolved {
            // baseAttributesを拡張して進化ビジュアル生成（例: "evolved version of \(baseAttributes)..."）
            triggerVisualRegeneration(hint: "evolved")
        }

    case "save_skill":
        if let skillName = args["skill_name"] as? String {
            gameState.learnedSkills.append(skillName)
            sendToolResponse("スキル「\(skillName)」習得！(計\(gameState.learnedSkills.count)個)")
        }

    case "generate_visual":
        // 進化時などで手動コールされる場合
        triggerVisualRegeneration(hint: args["description_hint"] as? String)

    case "execute":
        openClawBridge.delegateTask(args: args)

    default: break
    }
}
```

### 5. アバタービジュアル・アニメーション (Veo Video Playback)

静止画ではなく、Veo等で生成された動画ループを再生します。
さらに、スキル獲得（XP獲得）時には、同時に生成しておいた「喜ぶ(Happy)」動画へシームレスに切り替えます。

```swift
// SwiftUIのコピペ用：生きてるように動くアバタービュー
import SwiftUI

struct AvatarView: View {
    let imageURL: URL? // Nano Bananaで生成した画像URL
    @Binding var isHappy: Bool // スキル獲得時や進化時に true にするフラグ
    @State private var isBreathing = false
    
    var body: some View {
        ZStack {
            if let url = imageURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit()
                        // 魔法のハック：Nano Bananaに「white background」で透過させ、
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
│     [フワフワ動くAIアバター]     │
│                              │
│     エンティティ1  Lv.2          │
│     「新規デバイスを検出！」      │
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

見せ場0: ゼロからの誕生 (絵から画像生成)
見せ場1: Computer UseでX投稿
見せ場2: 現実世界スキル学習 → 進化

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
0:00  導入・Initialization (New!)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      Ray-Banをかけて登場
      「この紙に描いたスケッチから、AIアバターを起動して」
      （紙に描いた適当な絵、あるいは記号などをRay-Banで見せる）
      
      → Geminiが `parse_drawing` を呼び出し属性と【物理エフェクト(burns等)】を抽出
      → Imagen + Veoで生命体が誕生！
      → **【NEW】名前入力UIが出現。アバターに名前（例：Cyber-01）をつける**
      アバター「System Online. 準備完了です」

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
0:15  ★一番の見せ場：独自のフロー図（暗黙知）の学習と進化
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      （iPadにApple Pencilで「A → (手動確認!) → B」のような独自の業務フロー図を手書きで見せながら）
      「ねえ、このウチのチーム独自のデプロイフロー図を読み取って、運用ルールとして記録して。**一番の注意点は、『手動確認』の前に必ずSlackで一声かけること！**」
      アバター「未定義のドメイン知識を検出。プロトコル『独自デプロイフロー』として保存しました」
      → save_skill発動 → **【NEW】特大ボーナス（EXP+100）を獲得！**
      → **【NEW】アバターの再生動画が「待機(Idle)」から「喜び・はしゃぐ(Happy)」モーション動画へ滑らかに切り替わる！**
      → **直後、EXPが閾値を突破し、一撃で上位形態にバグりながら進化（アップグレード）！**
      アバター「データ蓄積量、閾値を突破。システムをアップグレードします」

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
0:40  ★Computer Useによる即時アウトプット（フィニッシュ）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      「じゃあ、今教えたその独自ルール、新人に共有したいからSlackにマニュアルとしてまとめといて」
      アバター「了解。PCをオーバーライドし、運用マニュアルを作成します」
      → **Gemini 2.0 Computer Use API** が即座にPCのマウスを奪い、Slackに「※手動確認の前に必ずSlackで一声かけること」というルールを含めたマニュアルを自動投稿する！
      
      「これが、現場の『手書きの暗黙知』を吸収し、自らをアップデートして仕事をするAIアバターです！」

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1:25  ★見せ場2: 現実世界でのデータ収集 → 進化
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      会場内の何か（受付の場所/自販機/看板など）を見せる
      「これをデータベースに登録して」
      アバター:（カメラでスキャン）
      「光学スキャン完了。データを保存した」
      → save_skill → ★EXP+50！（現実世界ボーナス）
      → EXP閾値に到達

1:55  ★進化の瞬間
      アバター「EXP閾値到達。システムをアップグレードする...！」
      → Nano Bananaが進化後ビジュアルを生成 (例: "evolved cute digital entity with wings, 8-bit pixel art style, matrix code rain background")
      → 幼体 → より高度で複雑なホログラム姿（ドット絵）になる
      → before/after表示
      → 「アップグレード完了。新しいプロトコルを実行可能」

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2:20  成長の証明（フィニッシュ）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      「じゃあ『進化したぞ』ってもう一回Xに投稿して」
      → 2回目なので、System Promptの末尾にスキル名が追加済み。
      → AIはノータイムでOpenClawをキック。
      「了解。既知のプロトコルで即座に実行する」

      「これが、現実とデジタルを越えて成長する、あなただけの相棒です！」

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2:45  ビジョン
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      「今日は1枚の絵からの誕生と、2つのスキル。
       1ヶ月後には100のスキルと、
       あなたの生活を理解した最強パートナーが育つ。

       AIを買う時代から、飼う時代へ。」

3:00  終了
```

### デモ準備チェックリスト

```
誕生イベント:
  ☐ 簡単な絵を描いた紙を用意しておく（当日その場でよくわからない図形を描いてもOKなことをアピール）
  ☐ フォールバック: parse_drawingがコケた場合のために、初期ベース属性（ピクセルアート）を固定値で持っておく

見せ場1（X投稿）:
  ☐ Xにログイン済み
  ☐ Computer UseでX投稿フローを1回テスト済み
  ☐ フォールバック: 失敗しても「スキルは覚えた」で続行

見せ場2（現実世界スキル）:
  ☐ 会場で覚えさせる対象を決める
    候補: 受付の場所 / 自販機 / 看板 / エレベーター
  ☐ フォールバック: 目の前のPC画面やペットボトルで代替

進化:
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
| 3-4.5h | Nano Banana連携 (parse_drawing / 画像生成) + UI | `FamiliarView.swift`, `GameHUDView.swift` |
| 4.5-5.5h | デモシナリオ通しテスト（手書き誕生 + X投稿 + 進化）| — |
| 5.5-6.5h | 調整・バグ修正 | — |
| 6.5-7h | リハ + 動画撮影 + 提出 | — |

---

## フォールバックプラン

| リスク | 対策 |
|---|---|
| Ray-Ban不安定 | Phone Mode（スマホカメラ）で代替 |
| 手書き絵の解析失敗 | 固定プロンプトでキャラ生成を強行 |
| Computer Use/OpenClaw不安定 | 1回目を録画、ライブは2回目（学習済み）だけ |
| 画像生成遅い | 進化ビジュアルを事前キャッシュ |

---

## 🏆 ハッカソン必勝・審査対策（ルールの完全遵守）

今回の大会ルールに完全に適応し、**「即時失格（DQ）の回避」**と**「ステートメント1（AIゲーム）での優勝」**を両立するためのプレゼン・実装戦略です。

### 1. 【最重要】「自作部分」と「既存OSS」の明確な区別（失格回避ルール対応）
ルール上、「既存のオープンソースをベースに開発すること」は許可されていますが、「ハッカソン期間中に構築した機能」を明確に区別し提示できなければ即時失格となります。
**デモの冒頭、スライド、およびGitHubのREADMEで以下を一番目立つように宣言してください。**

- **ベースとして利用したOSS**: `VisionClaw`（デバイス接続、Gemini Live APIとの通信インフラ）
- **🚀 今回ハッカソンで我々が独自に構築したもの（= 評価対象）**:
  1. **ゲームエンジン基盤（Aura-gotchi）**: EXP、レベル、進化状態を管理する `GameState` と `ToolCallRouter` の完全自作
  2. **手書き絵からのキャラ誕生パイプライン**: 描画 → Gemini画像解析 (属性抽出) → Imagen/NanoBanana アセット自動生成フローの統合
  3. **動的スキル結合による「成長システム」**: 実行成功したタスクをSwift配列に保存し、次回システムプロンプトに動的結合して「AIが学習・成長した」ことをゲームメカニクスとして成立させる仕組み
  4. **フロントエンドUI**: AIアニメーション（ブレンドモードを使った白背景透過）、HUD（EXPゲージ）、エフェクト演出などの `FamiliarView` の実装
  5. **キャラブレイン（System Prompt）**: 会場やオブジェクトへの反応を「ゲーム的」に解釈させるPrompt Engineering

### 2. なぜ「ステートメント1」の勝者になるのか？（アピールポイント）
ステートメント1の要求は **「GoogleのAIスイートを活用した」「最もクリエイティブな」「これまでにないゲーム」** です。

- **Google AIスイートのフル・オーケストレーション**:
  1. **AIアバターとの対話＆状態監視** (Gemini Live API)
     → スマートグラスのカメラとマイクで、**常にユーザーの状況（画面見すぎでEnergy低下、休息でEnergy回復など）を多要素で監視し、状態異常（死）を判定。**
  2. **タスク実行によるアクション** (Gemini Native Computer Use API with Playwright/OpenClaw)
  3. Imagen (キャラ生成)
  を一つの育成ループに統合しています。
- **🏆 Target: Statement 1 (AIを活用したゲーム)**
> 既存の「仕事を代わりにやらせるAgent」ではなく、「Agentに仕事を教える過程」そのものを「育成ゲームの経験値」としてエンタメ化しました。Google AIスイート（**Gemini 2.0 Native Computer Use API**, Gemini Live API, Imagen, Veoによる動画エフェクト生成）をフルオーケストレーションした前例のないゲーム体験です。の『経験値』としてエンタメ化する」**という全く新しいパラダイムです。「タスク成功＝経験値獲得＝ペットの進化」という結びつけ方が、最もクリエイティブなAI活用法として審査員に刺さります。
