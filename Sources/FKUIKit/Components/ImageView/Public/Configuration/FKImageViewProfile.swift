import UIKit

/// Preset integration profiles balancing features against view hierarchy depth.
///
/// Use ``FKImageViewProfile/listCell`` in `UITableView` / `UICollectionView` thumbnails where failure
/// overlays and loading chrome should stay minimal.
public enum FKImageViewProfile: Sendable {
  /// Default feature set: placeholders, loading chrome, failure overlay, and retry.
  case full
  /// Feed-style thumbnail: color placeholder, no inline failure overlay, no loading chrome.
  case listCell
  /// Image + color fill only; no failure overlay or loading chrome.
  case minimal
}

public extension FKImageViewConfiguration {
  /// Returns a configuration tuned for `profile`.
  static func profile(_ profile: FKImageViewProfile) -> FKImageViewConfiguration {
    switch profile {
    case .full:
      return FKImageViewConfiguration()
    case .listCell:
      var config = FKImageViewConfiguration()
      config.appearance.cornerStyle = .fixed(8)
      config.appearance.successTransition = .none
      config.loading.placeholder = .color(.secondarySystemFill)
      config.loading.loadingPresentation = .init(progressMode: .none, includesSkeleton: false)
      config.failure.showsFailureOverlay = false
      config.failure.isRetryEnabled = false
      return config
    case .minimal:
      var config = FKImageViewConfiguration()
      config.appearance.successTransition = .none
      config.loading.placeholder = .color(.tertiarySystemFill)
      config.loading.loadingPresentation = .init(progressMode: .none, includesSkeleton: false)
      config.failure.showsFailureOverlay = false
      config.failure.isRetryEnabled = false
      return config
    }
  }
}
