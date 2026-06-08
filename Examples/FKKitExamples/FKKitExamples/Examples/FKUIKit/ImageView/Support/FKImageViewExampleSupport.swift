import FKCoreKit
import FKUIKit
import UIKit

enum FKImageViewExampleURLs {
  static func photo(id: Int, size: Int = 240) -> URL {
    URL(string: "https://picsum.photos/id/\(id)/\(size)/\(size)")!
  }

  static var notFound: URL {
    URL(string: "https://httpbin.org/status/404")!
  }

  static func feedIDs(count: Int) -> [Int] {
    (0 ..< count).map { 10 + ($0 * 7) % 80 }
  }
}

enum FKImageViewExampleFactory {
  static func makeLocalFileURL() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("fkimageview-demo.jpg")
    guard !FileManager.default.fileExists(atPath: url.path) else { return url }
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 240, height: 240))
    let image = renderer.image { context in
      UIColor.systemTeal.setFill()
      context.fill(CGRect(x: 0, y: 0, width: 240, height: 240))
      let attrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.boldSystemFont(ofSize: 22),
        .foregroundColor: UIColor.white,
      ]
      "Local".draw(at: CGPoint(x: 72, y: 108), withAttributes: attrs)
    }
    if let data = image.jpegData(compressionQuality: 0.85) {
      try? data.write(to: url)
    }
    return url
  }

  static func bindState(_ imageView: FKImageView, label: UILabel) {
    imageView.onStateChange = { state in
      label.text = "State: \(FKImageViewExampleFormatting.describe(state))"
    }
    label.text = "State: \(FKImageViewExampleFormatting.describe(imageView.state))"
  }
}

enum FKImageViewExampleFormatting {
  static func describe(_ state: FKImageViewState) -> String {
    switch state {
    case .idle: return "idle"
    case .placeholder: return "placeholder"
    case .loading: return "loading"
    case .success: return "success"
    case .failure(let reason): return "failure(\(describe(reason)))"
    }
  }

  static func describe(_ reason: FKImageViewFailureReason) -> String {
    switch reason {
    case .network: return "network"
    case .decode: return "decode"
    case .cancelled: return "cancelled"
    case .offline: return "offline"
    case .custom(let message): return "custom(\(message ?? "nil"))"
    }
  }

  static func describe(_ event: FKImageLoaderEvent) -> String {
    switch event {
    case .cacheHit(let level): return "cacheHit(\(level))"
    case .fetchStarted: return "fetchStarted"
    case .fetchCompleted(let duration): return String(format: "fetchCompleted(%.2fs)", duration)
    case .fetchFailed: return "fetchFailed"
    case .evicted(let count): return "evicted(\(count))"
    }
  }
}

/// Configurable stub for custom-loader and offline failure demos.
@MainActor
final class FKImageExampleStubLoader: FKImageLoading {
  enum Mode: Sendable {
    case shared
    case httpError(Int)
    case offline
    case decodeFailed
  }

  var mode: Mode = .shared

  func loadImage(for request: FKImageLoadRequest) async throws -> UIImage {
    switch mode {
    case .shared:
      try await FKImageLoader.shared.loadImage(for: request)
    case .httpError(let code):
      throw FKImageLoaderError.httpStatus(code: code)
    case .offline:
      throw FKImageLoaderError.offline
    case .decodeFailed:
      throw FKImageLoaderError.decodeFailed
    }
  }

  func cancelLoad(for request: FKImageLoadRequest) {
    FKImageLoader.shared.cancelLoad(for: request)
  }
}

/// Adds an artificial delay so loading chrome stays visible in demos.
@MainActor
final class FKImageExampleDelayedLoader: FKImageLoading {
  var delay: TimeInterval = 2

  func loadImage(for request: FKImageLoadRequest) async throws -> UIImage {
    let nanoseconds = UInt64(max(0, delay) * 1_000_000_000)
    try await Task.sleep(nanoseconds: nanoseconds)
    try Task.checkCancellation()
    return try await FKImageLoader.shared.loadImage(for: request)
  }

  func cancelLoad(for request: FKImageLoadRequest) {
    FKImageLoader.shared.cancelLoad(for: request)
  }
}

extension UIViewController {
  func fk_imagePresentAlert(title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: FKUIKitI18n.string("fkuikit.common.ok"), style: .default))
    present(alert, animated: true)
  }
}
