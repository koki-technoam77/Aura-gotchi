import Foundation

@MainActor
class OpenClawBridge: ObservableObject {
  @Published var lastToolCallStatus: ToolCallStatus = .idle

  private let session: URLSession
  private var sessionKey: String

  init() {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 120
    self.session = URLSession(configuration: config)
    self.sessionKey = OpenClawBridge.newSessionKey()
  }

  func resetSession() {
    sessionKey = OpenClawBridge.newSessionKey()
    NSLog("[OpenClaw] New session: %@", sessionKey)
  }

  private static func newSessionKey() -> String {
    let ts = ISO8601DateFormatter().string(from: Date())
    return "agent:main:glass:\(ts)"
  }

  // MARK: - URL construction

  private var baseURL: String {
    let host = GeminiConfig.openClawHost
    let port = GeminiConfig.openClawPort
    if port == 443 || port == 80 {
      return host
    }
    return "\(host):\(port)"
  }

  // MARK: - Agent Chat (session continuity via x-openclaw-session-key header)

  /// Maximum retries for 503 responses (cold-start on Cloudflare Workers).
  private static let maxRetries = 2
  private static let retryDelay: UInt64 = 3_000_000_000 // 3 seconds

  func delegateTask(
    task: String,
    toolName: String = "execute"
  ) async -> ToolResult {
    lastToolCallStatus = .executing(toolName)

    guard let url = URL(string: "\(baseURL)/v1/chat/completions") else {
      lastToolCallStatus = .failed(toolName, "Invalid URL")
      return .failure("Invalid gateway URL")
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(GeminiConfig.openClawGatewayToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(sessionKey, forHTTPHeaderField: "x-openclaw-session-key")

    let body: [String: Any] = [
      "model": "openclaw",
      "messages": [
        ["role": "user", "content": task]
      ],
      "stream": false
    ]

    do {
      request.httpBody = try JSONSerialization.data(withJSONObject: body)

      var lastCode = 0
      for attempt in 0...Self.maxRetries {
        let (data, response) = try await session.data(for: request)
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode ?? 0
        lastCode = statusCode

        // Retry on 503 (cold-start) unless we've exhausted retries
        if statusCode == 503 && attempt < Self.maxRetries {
          NSLog("[OpenClaw] 503 on attempt %d, retrying in 3s…", attempt + 1)
          try await Task.sleep(nanoseconds: Self.retryDelay)
          continue
        }

        guard (200...299).contains(statusCode) else {
          let bodyStr = String(data: data, encoding: .utf8) ?? "no body"
          NSLog("[OpenClaw] Chat failed: HTTP %d - %@", statusCode, String(bodyStr.prefix(200)))
          lastToolCallStatus = .failed(toolName, "HTTP \(statusCode)")
          return .failure("Agent returned HTTP \(statusCode)")
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let first = choices.first,
           let message = first["message"] as? [String: Any],
           let content = message["content"] as? String {
          NSLog("[OpenClaw] Agent result: %@", String(content.prefix(200)))
          lastToolCallStatus = .completed(toolName)
          return .success(content)
        }

        let raw = String(data: data, encoding: .utf8) ?? "OK"
        NSLog("[OpenClaw] Agent raw: %@", String(raw.prefix(200)))
        lastToolCallStatus = .completed(toolName)
        return .success(raw)
      }

      // Should not reach here, but handle gracefully
      lastToolCallStatus = .failed(toolName, "HTTP \(lastCode)")
      return .failure("Agent returned HTTP \(lastCode) after retries")
    } catch {
      NSLog("[OpenClaw] Agent error: %@", error.localizedDescription)
      lastToolCallStatus = .failed(toolName, error.localizedDescription)
      return .failure("Agent error: \(error.localizedDescription)")
    }
  }
}
