import Foundation

/// Thread-safe log of background handler invocations (survives across demo screens).
actor FKBackgroundTaskExampleExecutionStore {
  static let shared = FKBackgroundTaskExampleExecutionStore()

  private var lines: [String] = []

  private init() {}

  func append(_ line: String) {
    let stamp = ISO8601DateFormatter().string(from: Date())
    lines.append("[\(stamp)] \(line)")
  }

  func snapshot() -> [String] {
    lines
  }

  func clear() {
    lines.removeAll()
  }
}
