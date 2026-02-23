import Foundation
import UIKit

/// キャラクター生成パイプラインの結果
struct CharacterGenerationResult {
    let imageURL: URL?
    let videoURL: URL?
    let attributes: String
    let behavior: String
    let errorDetail: String?
}

@MainActor
class CharacterGenerationService {

    /// Generate familiar visual (+ video) from text description
    /// - Parameters:
    ///   - prompt: 属性キーワード (例: "fire, round")
    ///   - behavior: 物理的振る舞い (例: "burns and floats gently")
    ///   - gameState: 結果を直接セットする GameState (optional)
    /// - Returns: 生成結果 (静止画URL, 動画URL)
    static func generateFromText(prompt: String,
                                 behavior: String = "",
                                 gameState: GameState? = nil) async -> CharacterGenerationResult {
        NSLog("[CharGenService] generateFromText: prompt=%@, behavior=%@", prompt, behavior)

        // Step 1: Imagen で静止画を生成
        let imagenService = ImagenService()
        let fullPrompt = prompt
        var imageURL: URL?

        if let urlString = await imagenService.generateFamiliarVisual(
            level: 1, skillCount: 0, hint: fullPrompt
        ) {
            imageURL = URL(string: urlString)
            NSLog("[CharGenService] generateFromText: Imagen success -> %@", urlString)
        } else {
            NSLog("[CharGenService] generateFromText: ImagenService returned nil — error: %@",
                  imagenService.lastError ?? "unknown")
            // Imagen失敗時はエラー詳細を返す
            if imageURL == nil {
                return CharacterGenerationResult(imageURL: nil,
                                                 videoURL: nil,
                                                 attributes: prompt,
                                                 behavior: behavior,
                                                 errorDetail: imagenService.lastError)
            }
        }

        // gameState に静止画をセット（Veo完了前に表示可能にする）
        if let gs = gameState {
            gs.currentVisualURL = imageURL
            gs.baseAttributes = prompt
            gs.behaviorPrompt = behavior
        }

        // Step 2: Veo で動画を生成（静止画が取得できた場合、常に1つ生成する）
        var videoURL: URL?
        if let imgURL = imageURL,
           let imageData = try? Data(contentsOf: imgURL),
           let uiImage = UIImage(data: imageData) {
            // Default behavior if none provided — ensures at least one video is always generated
            let videoBehavior = behavior.isEmpty
                ? "idle animation, gentle breathing and bobbing movement, soft glow"
                : behavior
            NSLog("[CharGenService] generateFromText: Starting Veo video generation (behavior='%@')...", videoBehavior)
            let veoService = VeoService()
            videoURL = await veoService.generateVideo(initialImage: uiImage,
                                                      behaviorPrompt: videoBehavior)
            if let vURL = videoURL {
                NSLog("[CharGenService] generateFromText: Veo success -> %@",
                      vURL.absoluteString)
            } else {
                NSLog("[CharGenService] generateFromText: Veo failed — continuing with image only (fallback)")
            }
        } else {
            NSLog("[CharGenService] generateFromText: Skipping Veo (no image available)")
        }

        // gameState に動画をセット
        if let gs = gameState {
            gs.currentVideoURL = videoURL
        }

        return CharacterGenerationResult(imageURL: imageURL,
                                         videoURL: videoURL,
                                         attributes: prompt,
                                         behavior: behavior,
                                         errorDetail: nil)
    }

    /// Generate familiar visual (+ video) from an image (photo or drawing)
    /// Pipeline: Gemini分析 -> 属性+振る舞い -> Imagen静止画 -> Veo動画
    /// - Parameters:
    ///   - image: 入力画像 (手書きスケッチや写真)
    ///   - gameState: 結果を直接セットする GameState (optional)
    /// - Returns: 生成結果 (静止画URL, 動画URL)
    static func generateFromImage(image: UIImage,
                                  gameState: GameState? = nil) async -> CharacterGenerationResult {
        NSLog("[CharGenService] generateFromImage: image size=%dx%d",
              Int(image.size.width), Int(image.size.height))

        // Step 1: Gemini で属性 + 振る舞いを抽出
        let analysisResult = await analyzeImage(image)
        let attributes = analysisResult.attributes
        let behavior = analysisResult.behavior
        NSLog("[CharGenService] generateFromImage: attributes=%@, behavior=%@", attributes, behavior)

        // Step 2 & 3: Imagen + Veo (generateFromText に委譲)
        return await generateFromText(prompt: attributes,
                                      behavior: behavior,
                                      gameState: gameState)
    }

    // MARK: - Legacy compatibility wrappers

    /// 後方互換: 静止画URLのみを返す旧インターフェース
    static func generateFromText(prompt: String) async -> URL? {
        let result = await generateFromText(prompt: prompt, behavior: "", gameState: nil)
        return result.imageURL
    }

    /// 後方互換: 静止画URLのみを返す旧インターフェース
    static func generateFromImage(image: UIImage) async -> URL? {
        let result = await generateFromImage(image: image, gameState: nil)
        return result.imageURL
    }

    // MARK: - Gemini Analysis

    /// Gemini解析結果: 属性キーワードと物理的振る舞い
    private struct AnalysisResult {
        let attributes: String
        let behavior: String
    }

    /// Call Gemini REST API to analyze an image and extract creature attributes + behavior
    /// レスポンスフォーマット: "fire, round | burns and floats gently"
    private static func analyzeImage(_ image: UIImage) async -> AnalysisResult {
        NSLog("[GeminiAnalysis] analyzeImage: input size=%dx%d",
              Int(image.size.width), Int(image.size.height))

        let fallback = AnalysisResult(attributes: "mysterious, ethereal",
                                      behavior: "drifts and shimmers softly")

        // Resize image to reduce payload
        let maxDim: CGFloat = 512
        let resized = resizeImage(image, maxDimension: maxDim)
        guard let jpegData = resized.jpegData(compressionQuality: 0.7) else {
            NSLog("[GeminiAnalysis] Failed to produce JPEG data from resized image")
            return fallback
        }
        let base64 = jpegData.base64EncodedString()
        NSLog("[GeminiAnalysis] Base64 payload length: %d", base64.count)

        let apiKey = GeminiConfig.apiKey
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)") else {
            NSLog("[GeminiAnalysis] Failed to construct URL")
            return fallback
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": """
                        Interpret this hand-drawn picture as a unique fantasy RPG creature.

                        Extract TWO things:
                        1. A vivid visual description of the creature in English (10-20 words). Include: element/material, body shape, color scheme, distinctive features, texture. Be SPECIFIC — every drawing is different.
                        2. A short physical behavior/animation description (5-10 words)

                        Reply ONLY in this exact format, nothing else:
                        DESCRIPTION | BEHAVIOR

                        Examples:
                        a fiery red slime with molten lava core and orange dripping edges | burns and floats gently
                        an icy blue dragon with crystalline wings and frost-tipped tail | glides with trailing frost particles
                        a rusty mechanical spider with exposed bronze gears and electric sparks | rotates gears and sparks with electricity
                        a translucent green water blob with swirling bubbles inside | wobbles and drips with rippling surface
                        a dark purple shadow cat with glowing violet eyes and smoky tendrils | slinks and phases through shadows
                        """],
                        ["inlineData": ["mimeType": "image/jpeg", "data": base64]]
                    ]
                ]
            ]
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            NSLog("[GeminiAnalysis] Failed to serialize request body to JSON")
            return fallback
        }
        request.httpBody = httpBody

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                NSLog("[GeminiAnalysis] API error: %@", String(data: data, encoding: .utf8) ?? "unknown")
                return fallback
            }

            // Parse Gemini response
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let first = candidates.first,
                  let content = first["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let textPart = parts.first,
                  let text = textPart["text"] as? String else {
                NSLog("[GeminiAnalysis] Failed to parse response")
                return fallback
            }

            NSLog("[GeminiAnalysis] Raw response: %@", text)

            // Clean up the response
            let cleaned = text
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "'", with: "")
                .replacingOccurrences(of: "\"", with: "")
            let lastLine = cleaned.components(separatedBy: .newlines).last ?? cleaned
            let trimmed = lastLine.trimmingCharacters(in: .whitespacesAndNewlines)

            // パイプ区切りで属性と振る舞いを分離
            let components = trimmed.components(separatedBy: "|")
            let attributes = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let behavior: String
            if components.count >= 2 {
                behavior = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                // パイプがない場合はデフォルトの振る舞いを割り当て
                behavior = "moves and glows gently"
            }

            let finalAttributes = attributes.isEmpty ? "mysterious, ethereal" : attributes
            let finalBehavior = behavior.isEmpty ? "drifts and shimmers softly" : behavior

            NSLog("[GeminiAnalysis] Parsed attributes: %@", finalAttributes)
            NSLog("[GeminiAnalysis] Parsed behavior: %@", finalBehavior)

            return AnalysisResult(attributes: finalAttributes, behavior: finalBehavior)

        } catch {
            NSLog("[GeminiAnalysis] Network error: %@", error.localizedDescription)
            return fallback
        }
    }

    // MARK: - Utilities

    private static func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        if ratio >= 1.0 { return image }
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        return resized
    }
}
