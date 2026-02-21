# Aura-gotchi: 現実世界に棲むAI使い魔 🐉✨ / AI Familiar in the Real World

![Aura-gotchi](../assets/cover.png)
*(※ Image placeholder - replace with actual screenshot or logo)*

---

## 🇯🇵 日本語 (Japanese)

**「AIを買う時代から、飼う（育てる）時代へ」**

Meta Ray-Banスマートグラスを通して現実世界に出現する、あなただけの「AI使い魔」育成・使役ゲームです。
ユーザーが手描きした絵から誕生し、現実世界のオブジェクトやデジタルタスク（X投稿、Web検索など）を実行することで**「スキル」**を学習。経験値（EXP）を溜めることで姿形が**「進化」**していく、全く新しい体験を提供します。

> **🏆 Target: Statement 1 (AIを活用したゲーム)**
> 既存の「仕事を代わりにやらせるAgent」ではなく、「Agentに仕事を教える過程」そのものを「育成ゲームの経験値」としてエンタメ化しました。Google AIスイート（Gemini Live API, Computer Use, Imagen 等）をフルオーケストレーションした前例のないゲーム体験です。

### ⚠️ ハッカソン審査員の方へ：貢献内容の明確化

本プロジェクトは、オープンソースプロジェクトである [VisionClaw](https://github.com/sseanliu/VisionClaw) (Meta Wearables DAT SDK + Gemini Live API の繋ぎ込み部分) をベースとして機能拡張を行っています。

**ハッカソンルールの「貢献内容を明確に区別」に従い、今回私たちがゼロから構築した機能（= 評価対象）を以下に明記します。**

#### 🚀 今回のハッカソンで独自に構築した機能（自作部分）
1. **Aura-gotchi ゲームエンジン基盤**: 使い魔のEXP、レベル、進化状態を管理する `GameState` と `ToolCallRouter` 上のゲームロジック完全自作。
2. **手書き絵からの「誕生」パイプライン**: ユーザーの手書き絵 → Gemini画像解析（属性抽出） → NanoBanana/Imagen によるアセット自動生成フローの構築。
3. **動的スキルプロンプトによる「自己成長システム」**: 実行成功したタスク（Computer Use等）をSwift側の配列に保存し、次回起動時のシステムプロンプトに動的結合することで、「AIがタスクを学習・記憶して成功率が上がる」という成長メカニクスをゲームシステムとして成立させた点。
4. **フロントエンドUI**: AIによって生成された画像を白背景透過（ブレンドモード）で現実世界にオーバーレイし、フワフワと息づかせる `FamiliarView` のアニメーション実装およびHUD（EXPゲージ等）の開発。
5. **キャラブレイン（System Prompt）**: ただのAIアシスタントではなく、カメラに映る「人間＝冒険者」「物体＝アイテム」としてゲーム視点で解釈させるプロンプトエンジニアリング。

#### 📦 ベースとして利用したOSS (VisionClaw)
- Meta Ray-BanグラスとのBluetooth/Wi-Fi通信および映像・音声取得レイヤー
- Gemini Live API (WebSocket) とのリアルタイム通信インフラ
- OpenClaw (ローカルPCの実行エージェント) への通信ルーティングの基礎基盤

### 🎮 遊び方 (How to Play)

1. **誕生 (Birth)**
   ゲーム開始時、紙に簡単な「魔法生物の絵」を描きます。使い魔（Gemini）がカメラ越しにそれを認識・解析し、その属性情報からあなただけの使い魔（Lv.1）の3Dビジュアルが生成されます。
2. **学習と成長 (Learn & Grow)**
   - **話しかける:** 日常の会話で少しEXPが貯まります。
   - **現実世界のモノを見せる:** カメラ越しに珍しいものを見せると、使い魔がそれを認識してEXPが貯まります（+ 現実世界ボーナス）。
   - **タスクを教える:** 「Xにこの写真を投稿して」など、PC（OpenClaw/Computer Use連携）でのタスクを依頼し、成功するとそのスキルを「習得」します。次回からは一瞬で成功させるようになります（特大EXPボーナス）。
3. **進化 (Evolution)**
   EXPが一定の閾値（Lv1→Lv2: 100EXP, Lv2→Lv3: 300EXP...）に達すると、使い魔のビジュアルが再生成され、**よりカッコいい（または可愛い）姿へ進化**します！

### 🛠 動作環境・セットアップ (Quick Start)

*(ベースシステムであるVisionClawのセットアップに準じます)*

1. **リポジトリのクローン**
   ```bash
   git clone https://github.com/koki-technoam77/Aura-gotchi.git
   cd Aura-gotchi/VisionClaw/samples/CameraAccess
   open CameraAccess.xcodeproj
   ```
2. **Gemini API Keyの設定**
   `samples/CameraAccess/CameraAccess/Gemini/GeminiConfig.swift` にAPIキーを設定してください。
3. **ビルド＆ラン**
   - iOS 17.0+ のiPhone実機を接続し、Xcodeからビルドします。
   - **グラスなし**: 「Start on iPhone」をタップ。
   - **グラスあり**: Meta AIアプリ経由で接続し、「Start Streaming」をタップ。
4. **OpenClaw (PC側連携) の設定**
   - [OpenClaw](https://github.com/nichochar/openclaw) をセットアップし起動後、`GeminiConfig.swift` の `openClawHost`, `openClawPort`, `openClawGatewayToken` を設定します。

---
---

## 🇬🇧 English

**"From buying AI to raising it."**

Aura-gotchi is a virtual "AI Familiar" pet simulator and productivity tool that lives in the real world through your Meta Ray-Ban smart glasses.
Born from a simple drawing by the user, the familiar gains **"Skills"** by observing real-world objects and executing digital tasks (e.g., posting to X, searching the web). As it completes tasks, it earns Experience Points (EXP) and eventually **"Evolves"** into new, cooler forms. 

> **🏆 Target: Statement 1 (AI-Powered Game)**
> Instead of just asking an AI agent to do work for you, we gamified the process of *teaching* the AI how to do work. We fully orchestrated Google's AI suite (Gemini Live API, Computer Use, Imagen) into a digital pet simulator, creating an unprecedented, creative AI experience.

### ⚠️ To the Hackathon Judges: Clarification of Contributions

This project extends the open-source project [VisionClaw](https://github.com/sseanliu/VisionClaw) (which connects the Meta Wearables DAT SDK with the Gemini Live API).

**To strictly comply with the rule regarding "clearly distinguishing contributions", below are the features we built entirely from scratch during the hackathon (= what should be evaluated):**

#### 🚀 Built Entirely During the Hackathon (Our Custom Work)
1. **Aura-gotchi Game Engine**: Completely custom-built `GameState` and `ToolCallRouter` logic to manage the pet's EXP, levels, and evolution states.
2. **"Birth" Pipeline from Drawings**: The flow that allows a user to draw on paper → Gemini extracts attributes via image analysis → NanoBanana/Imagen generates the 3D game asset automatically.
3. **Self-Growth System via Dynamic Prompting**: Saving successfully executed tasks (via Computer Use) into a Swift array, and dynamically appending them to the System Prompt on the next run. This establishes a real game mechanic where the AI "remembers" learned tasks and executes them flawlessly next time.
4. **Frontend UI**: The `FamiliarView` animation implementation, which overlays AI-generated images onto the real world with white-background removal (blend mode), plus the HUD (EXP gauges, notifications).
5. **Character Brain (System Prompting)**: Prompt engineering that forces the AI to interpret the world through a game lens—seeing humans as "adventurers" and objects as "items."

#### 📦 Open Source Base Utilized (VisionClaw)
- Bluetooth/Wi-Fi connection layer for Meta Ray-Ban glasses audio/vid stream.
- The real-time WebSocket infrastructure for the Gemini Live API.
- The base routing code to communicate with OpenClaw (the local PC agent).

### 🎮 How to Play

1. **Birth**
   Draw a simple "magical creature" on paper. Gemini will see it through your glasses, parse its attributes (e.g., "fire slime"), and generate your very first Lv.1 3D visual companion.
2. **Learn & Grow**
   - **Talk**: Normal conversations grant small amounts of EXP.
   - **Show items**: Scanning interesting objects in the real world yields bonus EXP.
   - **Assign tasks**: Ask it to "Post this photo to X" using OpenClaw/Computer Use. Upon success, it "learns" the skill and becomes an expert at it, granting a massive EXP bonus.
3. **Evolution**
   Reach specific EXP thresholds (e.g., 100 EXP for Lv.2, 300 for Lv.3), and your familiar's visual asset will be regenerated to look more mature and powerful!

### 🛠 Setup (Quick Start)

*(Follows the base VisionClaw setup)*

1. **Clone the repo**
   ```bash
   git clone https://github.com/koki-technoam77/Aura-gotchi.git
   cd Aura-gotchi/VisionClaw/samples/CameraAccess
   open CameraAccess.xcodeproj
   ```
2. **Configure Gemini API Key**
   Open `samples/CameraAccess/CameraAccess/Gemini/GeminiConfig.swift` and paste your key.
3. **Build & Run**
   - Run on a physical iPhone (iOS 17.0+).
   - Tap "Start on iPhone" for non-glasses mode, or connect Ray-Bans and tap "Start Streaming".
4. **Configure OpenClaw (Optional, for Tasks)**
   - Start your local [OpenClaw](https://github.com/nichochar/openclaw) gateway and configure host/port/token inside `GeminiConfig.swift`.

---

## Team

*(Insert Team Name / Members)*

## License

The base of this project (originating from VisionClaw) follows its original LICENSE. Custom additions fall under the hackathon event guidelines.
