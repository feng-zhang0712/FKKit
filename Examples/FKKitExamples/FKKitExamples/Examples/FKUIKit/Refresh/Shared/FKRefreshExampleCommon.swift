import FKUIKit
import UIKit

/// Shared helpers for FKRefresh sample screens (not part of the library public API).
enum FKRefreshExampleCommon {

  /// Human-readable state for the status strip (examples only).
  static func stateDescription(_ state: FKRefreshState) -> String {
    switch state {
    case .idle: return "idle"
    case .pulling(let p): return String(format: "pulling(%.2f)", p)
    case .readyToRefresh: return "readyToRefresh"
    case .triggered: return "triggered"
    case .refreshing: return "refreshing"
    case .loadingMore: return "loadingMore"
    case .finished: return "finished"
    case .listEmpty: return "listEmpty"
    case .noMoreData: return "noMoreData"
    case .failed: return "failed"
    }
  }

  /// Two-frame animated image for ``FKGIFRefreshContentView`` (no asset file required).
  static func makeDemoAnimatedImage() -> UIImage {
    let size = CGSize(width: 36, height: 36)
    let colors: [UIColor] = [.systemOrange, .systemTeal]
    let frames: [UIImage] = colors.map { color in
      let r = UIGraphicsImageRenderer(size: size)
      return r.image { ctx in
        color.setFill()
        ctx.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
      }
    }
    return UIImage.animatedImage(with: frames, duration: 0.35) ?? frames[0]
  }

  /// Simulates async work; always invokes `work` on the main actor after `delay`.
  ///
  /// Uses `Task` + `MainActor` instead of `DispatchQueue.asyncAfter` so Refresh callbacks stay compatible with
  /// Swift 6 default actor isolation (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`).
  static func simulateRequest(delay: TimeInterval, _ work: @MainActor @escaping () -> Void) {
    Task { @MainActor in
      let nanos = UInt64(max(0, delay) * 1_000_000_000)
      try? await Task.sleep(nanoseconds: nanos)
      work()
    }
  }

  /// Async/await helper that mimics a network delay.
  static func simulateAsyncRequest(delay: TimeInterval) async throws {
    let nanos = UInt64(max(0, delay) * 1_000_000_000)
    try await Task.sleep(nanoseconds: nanos)
  }
}
