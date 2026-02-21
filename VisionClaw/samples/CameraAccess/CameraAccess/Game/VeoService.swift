import Foundation
import UIKit

/// Google Veo API (via Generative Language API) を使って静止画 + プロンプトから動画を生成するサービス
@MainActor
class VeoService {

    private let apiKey = GeminiConfig.apiKey

    /// Model priority: Veo 3 (preview) → Veo 2 (stable fallback)
    private let models = [
        "veo-3.0-generate-preview",
        "veo-2.0-generate-001"
    ]

    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"

    /// ポーリング間隔（秒）
    private let pollInterval: TimeInterval = 10.0

    /// ポーリングの最大回数（10秒 x 60 = 最大10分）
    private let maxPollAttempts = 60

    // MARK: - Public API

    /// 初期フレーム画像と振る舞いプロンプトから動画を生成する
    /// - Parameters:
    ///   - initialImage: 初期フレームとなる静止画
    ///   - behaviorPrompt: 物理的な振る舞いを示すプロンプト (例: "burns and floats gently")
    /// - Returns: 生成された動画のローカルファイルURL、失敗時はnil
    func generateVideo(initialImage: UIImage, behaviorPrompt: String) async -> URL? {
        NSLog("[VeoService] generateVideo: start — behavior='%@', imageSize=%dx%d",
              behaviorPrompt, Int(initialImage.size.width), Int(initialImage.size.height))

        // Step 1: 画像をBase64エンコード
        guard let pngData = initialImage.pngData() else {
            NSLog("[VeoService] Failed to produce PNG data from image")
            return nil
        }
        let base64Image = pngData.base64EncodedString()
        NSLog("[VeoService] Base64 payload length: %d", base64Image.count)

        // Try each model in priority order
        for (index, model) in models.enumerated() {
            NSLog("[VeoService] Trying model %d/%d: %@", index + 1, models.count, model)

            // Step 2: Long Running Operation を開始
            guard let operationName = await startGeneration(model: model,
                                                             base64Image: base64Image,
                                                             behaviorPrompt: behaviorPrompt) else {
                NSLog("[VeoService] startGeneration failed for model=%@ — trying next", model)
                continue
            }
            NSLog("[VeoService] Operation started: %@ (model=%@)", operationName, model)

            // Step 3: ポーリングで完了を待つ
            guard let videoDownloadURI = await pollForCompletion(operationName: operationName) else {
                NSLog("[VeoService] Polling failed or timed out for model=%@ — trying next", model)
                continue
            }
            NSLog("[VeoService] Video URI obtained: %@", videoDownloadURI)

            // Step 4: 動画をダウンロードしてDocumentsに保存
            guard let localURL = await downloadVideo(from: videoDownloadURI) else {
                NSLog("[VeoService] Failed to download video for model=%@", model)
                continue
            }
            NSLog("[VeoService] Video saved to: %@ (model=%@)", localURL.absoluteString, model)
            return localURL
        }

        NSLog("[VeoService] All models failed")
        return nil
    }

    /// 「通常待機用(Idle)」と「歓喜・成功用(Happy)」の2つの動画を同時に生成する
    /// - Parameters:
    ///   - initialImage: 初期フレームとなる静止画
    ///   - behaviorPrompt: 物理的な振る舞いを示すベースプロンプト
    /// - Returns: (idleURL, happyURL) のタプルのOptional
    func generateDualVideos(initialImage: UIImage, behaviorPrompt: String) async -> (idle: URL, happy: URL)? {
        let happyPrompt = "\(behaviorPrompt), extremely happy, celebrating, glowing super bright, fast energetic movement"
        
        async let idleTask = generateVideo(initialImage: initialImage, behaviorPrompt: behaviorPrompt)
        async let happyTask = generateVideo(initialImage: initialImage, behaviorPrompt: happyPrompt)
        
        let (idleURL, happyURL) = await (idleTask, happyTask)
        
        guard let idle = idleURL, let happy = happyURL else {
            NSLog("[VeoService] Failed to generate both videos. idle=%@, happy=%@", 
                  idleURL?.absoluteString ?? "null", 
                  happyURL?.absoluteString ?? "null")
            return nil
        }
        
        return (idle, happy)
    }

    // MARK: - Private: Start Generation

    private func startGeneration(model: String, base64Image: String, behaviorPrompt: String) async -> String? {
        let endpointURL = "\(baseURL)/models/\(model):predictLongRunning"
        guard let url = URL(string: endpointURL) else {
            NSLog("[VeoService] Failed to construct endpoint URL")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.timeoutInterval = 60

        // 動画生成プロンプト: 振る舞い記述を中心に
        let videoPrompt = "A fantasy creature \(behaviorPrompt), smooth animation loop, game sprite style"

        let body: [String: Any] = [
            "instances": [
                [
                    "prompt": videoPrompt,
                    "image": [
                        "inlineData": [
                            "mimeType": "image/png",
                            "data": base64Image
                        ]
                    ]
                ]
            ],
            "parameters": [
                "aspectRatio": "9:16",
                "durationSeconds": 5
            ]
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            NSLog("[VeoService] Failed to serialize request body to JSON")
            return nil
        }
        request.httpBody = httpBody

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                NSLog("[VeoService] No HTTP response received")
                return nil
            }

            guard httpResponse.statusCode == 200 else {
                NSLog("[VeoService] API error (HTTP %d): %@",
                      httpResponse.statusCode,
                      String(data: data, encoding: .utf8) ?? "unknown")
                return nil
            }

            // レスポンスから operation name を取得
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let name = json["name"] as? String else {
                NSLog("[VeoService] Failed to parse operation name from response: %@",
                      String(data: data, encoding: .utf8) ?? "unknown")
                return nil
            }

            return name

        } catch {
            NSLog("[VeoService] Network error in startGeneration: %@", error.localizedDescription)
            return nil
        }
    }

    // MARK: - Private: Poll for Completion

    private func pollForCompletion(operationName: String) async -> String? {
        let pollURLString = "\(baseURL)/\(operationName)"
        guard let pollURL = URL(string: pollURLString) else {
            NSLog("[VeoService] Failed to construct poll URL from: %@", pollURLString)
            return nil
        }

        for attempt in 1...maxPollAttempts {
            NSLog("[VeoService] Poll attempt %d/%d", attempt, maxPollAttempts)

            // 待機
            try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))

            var request = URLRequest(url: pollURL)
            request.httpMethod = "GET"
            request.addValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
            request.timeoutInterval = 30

            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    NSLog("[VeoService] Poll HTTP error (%d): %@",
                          statusCode,
                          String(data: data, encoding: .utf8) ?? "unknown")
                    continue
                }

                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    NSLog("[VeoService] Failed to parse poll response")
                    continue
                }

                // Check if operation is done
                if let done = json["done"] as? Bool, done {
                    NSLog("[VeoService] Operation completed at attempt %d", attempt)

                    // Extract video URI from response
                    if let responseObj = json["response"] as? [String: Any],
                       let generateVideoResponse = responseObj["generateVideoResponse"] as? [String: Any],
                       let generatedSamples = generateVideoResponse["generatedSamples"] as? [[String: Any]],
                       let firstSample = generatedSamples.first,
                       let video = firstSample["video"] as? [String: Any],
                       let uri = video["uri"] as? String {
                        return uri
                    }

                    // Check for error in response
                    if let error = json["error"] as? [String: Any] {
                        NSLog("[VeoService] Operation completed with error: %@",
                              String(describing: error))
                    } else {
                        NSLog("[VeoService] Operation done but failed to extract video URI: %@",
                              String(data: data, encoding: .utf8) ?? "unknown")
                    }
                    return nil
                }

                NSLog("[VeoService] Operation still running...")

            } catch {
                NSLog("[VeoService] Poll network error: %@", error.localizedDescription)
                continue
            }
        }

        NSLog("[VeoService] Polling timed out after %d attempts", maxPollAttempts)
        return nil
    }

    // MARK: - Private: Download Video

    private func downloadVideo(from uri: String) async -> URL? {
        // URIにAPIキーを付与してダウンロード（認証が必要な場合）
        guard var urlComponents = URLComponents(string: uri) else {
            NSLog("[VeoService] Failed to parse video URI: %@", uri)
            return nil
        }

        // APIキーをクエリパラメータに追加（ヘッダーでも渡す）
        var queryItems = urlComponents.queryItems ?? []
        queryItems.append(URLQueryItem(name: "key", value: apiKey))
        urlComponents.queryItems = queryItems

        guard let downloadURL = urlComponents.url else {
            NSLog("[VeoService] Failed to construct download URL")
            return nil
        }

        var request = URLRequest(url: downloadURL)
        request.addValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.timeoutInterval = 120

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                NSLog("[VeoService] Download failed (HTTP %d)", statusCode)
                return nil
            }

            // Documentsディレクトリに保存
            guard let documentsDir = FileManager.default.urls(for: .documentDirectory,
                                                               in: .userDomainMask).first else {
                NSLog("[VeoService] Failed to access documents directory")
                return nil
            }

            let fileName = "familiar_video_\(UUID().uuidString.prefix(8)).mp4"
            let fileURL = documentsDir.appendingPathComponent(fileName)

            try data.write(to: fileURL)
            NSLog("[VeoService] Video file saved: %@ (%d bytes)", fileURL.lastPathComponent, data.count)
            return fileURL

        } catch {
            NSLog("[VeoService] Download error: %@", error.localizedDescription)
            return nil
        }
    }
}
