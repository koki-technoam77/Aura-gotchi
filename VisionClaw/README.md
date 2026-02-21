# Aura-gotchi: 現実世界に棲むAI使い魔 �✨

![Aura-gotchi](../assets/cover.png)
*(※ Image placeholder - replace with actual screenshot or logo)*

**「AIを買う時代から、飼う（育てる）時代へ」**

Meta Ray-Banスマートグラスを通して現実世界に出現する、あなただけの「AI使い魔」育成・使役ゲームです。
ユーザーが手描きした絵から誕生し、現実世界のオブジェクトやデジタルタスク（X投稿、Web検索など）を実行することで**「スキル」**を学習。経験値（EXP）を溜めることで姿形が**「進化」**していく、全く新しい体験を提供します。

> **🏆 Target: Statement 1 (AIを活用したゲーム)**
> 既存の「仕事を代わりにやらせるAgent」ではなく、「Agentに仕事を教える過程」そのものを「育成ゲームの経験値」としてエンタメ化しました。Google AIスイート（Gemini Live API, Computer Use, Imagen 等）をフルオーケストレーションした前例のないゲーム体験です。

---

## ⚠️ ハッカソン審査員の方へ：貢献内容の明確化

本プロジェクトは、オープンソースプロジェクトである [VisionClaw](https://github.com/sseanliu/VisionClaw) (Meta Wearables DAT SDK + Gemini Live API の繋ぎ込み部分) をベースとして機能拡張を行っています。

**ハッカソンルールの「貢献内容を明確に区別」に従い、今回私たちがゼロから構築した機能（= 評価対象）を以下に明記します。**

### 🚀 今回のハッカソンで独自に構築した機能（自作部分）
1. **Aura-gotchi ゲームエンジン基盤**: 使い魔のEXP、レベル、進化状態を管理する `GameState` と `ToolCallRouter` 上のゲームロジック完全自作。
2. **手書き絵からの「誕生」パイプライン**: ユーザーの手書き絵 → Gemini画像解析（属性抽出） → NanoBanana/Imagen によるアセット自動生成フローの構築。
3. **動的スキルプロンプトによる「自己成長システム」**: 実行成功したタスク（Computer Use等）をSwift側の配列に保存し、次回起動時のシステムプロンプトに動的結合することで、「AIがタスクを学習・記憶して成功率が上がる」という成長メカニクスをゲームシステムとして成立させた点。
4. **フロントエンドUI**: AIによって生成された画像を白背景透過（ブレンドモード）で現実世界にオーバーレイし、フワフワと息づかせる `FamiliarView` のアニメーション実装およびHUD（EXPゲージ等）の開発。
5. **キャラブレイン（System Prompt）**: ただのAIアシスタントではなく、カメラに映る「人間＝冒険者」「物体＝アイテム」としてゲーム視点で解釈させるプロンプトエンジニアリング。

### 📦 ベースとして利用したOSS (VisionClaw)
- Meta Ray-BanグラスとのBluetooth/Wi-Fi通信および映像・音声取得レイヤー
- Gemini Live API (WebSocket) とのリアルタイム通信インフラ
- OpenClaw (ローカルPCの実行エージェント) への通信ルーティングの基礎基盤

---

## 🎮 遊び方 (How to Play)

1. **誕生 (Birth)**
   ゲーム開始時、紙に簡単な「魔法生物の絵」を描きます。使い魔（Gemini）がカメラ越しにそれを認識・解析し、その属性情報からあなただけの使い魔（Lv.1）の3Dビジュアルが生成されます。
2. **学習と成長 (Learn & Grow)**
   - **話しかける:** 日常の会話で少しEXPが貯まります。
   - **現実世界のモノを見せる:** カメラ越しに珍しいものを見せると、使い魔がそれを認識してEXPが貯まります（+ 現実世界ボーナス）。
   - **タスクを教える:** 「Xにこの写真を投稿して」など、PC（OpenClaw/Computer Use連携）でのタスクを依頼し、成功するとそのスキルを「習得」します。次回からは一瞬で成功させるようになります（特大EXPボーナス）。
3. **進化 (Evolution)**
   EXPが一定の閾値（Lv1→Lv2: 100EXP, Lv2→Lv3: 300EXP...）に達すると、使い魔のビジュアルが再生成され、**よりカッコいい（または可愛い）姿へ進化**します！

---

## 🛠 動作環境・セットアップ (Quick Start)

*(ベースシステムであるVisionClawのセットアップに準じます)*

### 1. リポジトリのクローン
```bash
git clone https://github.com/koki-technoam77/Aura-gotchi.git
cd Aura-gotchi/VisionClaw/samples/CameraAccess
open CameraAccess.xcodeproj
```

### 2. Gemini API Keyの設定
`samples/CameraAccess/CameraAccess/Gemini/GeminiConfig.swift` を開き、APIキーを設定してください。
```swift
static let apiKey = "YOUR_GEMINI_API_KEY"
```

### 3. ビルド＆ラン
- iOS 17.0+ のiPhone実機を接続し、Xcodeからビルド（Cmd+R）します。
- **グラスなしモード**: 画面の「Start on iPhone」をタップするとiPhoneの背面カメラでプレイできます。
- **グラスモード**: Meta AIアプリ経由でRay-Banを接続し、「Start Streaming」をタップします。

### 4. OpenClaw (PC側連携) の設定 ※タスク実行に必要
- 別途PC側で [OpenClaw](https://github.com/nichochar/openclaw) をセットアップし、Gatewayを起動してください。
- `GeminiConfig.swift` 内の `openClawHost`, `openClawPort`, `openClawGatewayToken` を環境に合わせて変更します。

---

## チームメンバー

*(ここにチーム名とメンバーを記載)*

## License

本プロジェクトのベース部分（VisionClaw起因）は元のLICENSEに準じます。独自追加部分については大会規定に従います。
