import UIKit

/// High-level load and presentation state for ``FKImageView``.
public enum FKImageViewState: Sendable {
  /// No URL set, or the view was reset.
  case idle
  /// URL set; showing placeholder while waiting to load or after a cache miss before load starts.
  case placeholder
  /// In-flight load; may show placeholder, skeleton, or progress chrome.
  case loading
  /// Loaded image applied and identity-checked.
  case success(UIImage)
  /// Load failed or was cancelled.
  case failure(FKImageViewFailureReason)
}

extension FKImageViewState: Equatable {
  public static func == (lhs: FKImageViewState, rhs: FKImageViewState) -> Bool {
    switch (lhs, rhs) {
    case (.idle, .idle), (.placeholder, .placeholder), (.loading, .loading):
      return true
    case (.success(let left), .success(let right)):
      return left === right
    case (.failure(let left), .failure(let right)):
      return left == right
    default:
      return false
    }
  }
}

/// Categorized failure surfaced by ``FKImageView``.
public enum FKImageViewFailureReason: Equatable, Sendable {
  /// Transport, HTTP, or generic fetch failure.
  case network
  /// Decode or corrupt payload.
  case decode
  /// Structured cancellation.
  case cancelled
  /// Reachability fast-fail or explicit offline error.
  case offline
  /// Host-provided message for custom loaders.
  case custom(message: String?)
}
