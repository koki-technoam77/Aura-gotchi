import Foundation
import UIKit

@MainActor
class ImagenService {

    private let apiKey = GeminiConfig.apiKey

    /// モデル優先順位: 標準 → Fast（"fast"がv1betaで未対応の場合のフォールバック）
    private let models = [
        "imagen-4.0-generate-001",
        "imagen-4.0-fast-generate-001"
    ]

    /// 最後のAPIエラー詳細（UI表示用）
    var lastError: String?

    /// Imagen 4 で使い魔ビジュアルを生成し、ローカルファイルURLを返す
    func generateFamiliarVisual(level: Int, skillCount: Int, hint: String) async -> String? {
        let prompt = buildPrompt(level: level, skillCount: skillCount, hint: hint)
        NSLog("[Imagen] Prompt: %@", prompt)

        // 複数モデルで試行
        for (index, model) in models.enumerated() {
            NSLog("[Imagen] Trying model %d/%d: %@", index + 1, models.count, model)
            if let result = await tryGenerate(model: model, prompt: prompt, level: level) {
                return result
            }
        }

        NSLog("[Imagen] All models failed")
        return nil
    }

    private func tryGenerate(model: String, prompt: String, level: Int) async -> String? {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):predict") else {
            NSLog("[Imagen] Failed to construct URL for model: %@", model)
            lastError = "URL build failed: \(model)"
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.timeoutInterval = 60

        let body: [String: Any] = [
            "instances": [
                ["prompt": prompt]
            ],
            "parameters": [
                "sampleCount": 1,
                "aspectRatio": "1:1"
            ]
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            NSLog("[Imagen] Failed to serialize request body")
            lastError = "Request serialization failed"
            return nil
        }
        request.httpBody = httpBody

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let responseBody = String(data: data, encoding: .utf8) ?? "unknown"

            guard let httpResponse = response as? HTTPURLResponse else {
                NSLog("[Imagen] No HTTP response")
                lastError = "No HTTP response"
                return nil
            }

            guard httpResponse.statusCode == 200 else {
                NSLog("[Imagen] API error (HTTP %d) model=%@: %@",
                      httpResponse.statusCode, model, responseBody)
                lastError = "HTTP \(httpResponse.statusCode): \(responseBody.prefix(200))"
                return nil
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let predictions = json["predictions"] as? [[String: Any]],
                  let first = predictions.first,
                  let base64String = first["bytesBase64Encoded"] as? String,
                  let imageData = Data(base64Encoded: base64String) else {
                NSLog("[Imagen] Failed to parse response (model=%@): %@", model, responseBody)
                lastError = "Response parse failed: \(responseBody.prefix(200))"
                return nil
            }

            // Remove white background → transparent PNG
            let finalData = removeWhiteBackground(from: imageData) ?? imageData

            // Save to documents directory
            let fileName = "familiar_lv\(level)_\(UUID().uuidString.prefix(8)).png"
            guard let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                NSLog("[Imagen] Failed to access documents directory")
                lastError = "Document directory access failed"
                return nil
            }
            let fileURL = documentsDir.appendingPathComponent(fileName)

            try finalData.write(to: fileURL)
            NSLog("[Imagen] Saved visual to: %@ (model=%@)", fileURL.absoluteString, model)
            lastError = nil
            return fileURL.absoluteString

        } catch {
            NSLog("[Imagen] Network error (model=%@): %@", model, error.localizedDescription)
            lastError = "Network error: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: - Background Removal

    /// Remove white/near-white pixels from the generated image, making them transparent.
    /// This lets the creature sprite float without a visible bounding box.
    private func removeWhiteBackground(from imageData: Data) -> Data? {
        guard let uiImage = UIImage(data: imageData),
              let cgImage = uiImage.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            NSLog("[Imagen] Failed to create CGContext for background removal")
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let pixelBuffer = context.data else { return nil }
        let pixels = pixelBuffer.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)

        // Threshold: pixels with R, G, B all >= 230 are considered "white"
        let threshold: UInt8 = 230
        var removedCount = 0
        for i in 0..<(width * height) {
            let offset = i * bytesPerPixel
            let r = pixels[offset]
            let g = pixels[offset + 1]
            let b = pixels[offset + 2]

            if r >= threshold && g >= threshold && b >= threshold {
                pixels[offset + 3] = 0  // Set alpha to 0 (transparent)
                removedCount += 1
            }
        }

        guard let outputImage = context.makeImage() else { return nil }
        let result = UIImage(cgImage: outputImage)
        NSLog("[Imagen] Background removal: %d/%d pixels made transparent", removedCount, width * height)
        return result.pngData()
    }

    // MARK: - Prompt Building

    private func buildPrompt(level: Int, skillCount: Int, hint: String) -> String {
        let baseCreature: String
        switch level {
        case 1:
            baseCreature = "a tiny cute baby creature hatchling, small round body, big curious eyes"
        case 2:
            baseCreature = "a young creature with small wing buds and emerging features, playful expression"
        case 3:
            baseCreature = "a majestic adolescent creature with spread wings and glowing patterns"
        default:
            baseCreature = "a powerful fully evolved creature with magnificent wings, ornate features, and luminous aura"
        }

        return """
        \(baseCreature), \
        \(hint.isEmpty ? "" : "inspired by: \(hint), ") \
        8-bit pixel art style, flat 2D game sprite, vibrant colors, \
        single creature centered on plain solid white background, \
        no text, no watermark, no shadows, clean edges.
        """
    }
}
