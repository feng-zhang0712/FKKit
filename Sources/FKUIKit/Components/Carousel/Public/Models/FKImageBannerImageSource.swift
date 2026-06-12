import UIKit

/// Image source for a single ``FKImageBannerSlide``.
public enum FKImageBannerImageSource: Equatable, @unchecked Sendable {
  /// Remote image URL with optional cache key override.
  case url(URL, cacheKey: String? = nil)

  /// In-memory image supplied by the host (not `Sendable`; use for short-lived promos).
  case image(UIImage)

  /// Named asset in a bundle.
  case named(String, bundle: Bundle? = nil)
}
