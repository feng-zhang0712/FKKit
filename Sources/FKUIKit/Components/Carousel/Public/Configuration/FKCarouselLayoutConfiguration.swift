import CoreGraphics
import UIKit

/// Horizontal layout mode for carousel pages.
public enum FKCarouselLayoutMode: Equatable, Sendable {
  /// One full-width page per viewport.
  case fullPage

  /// Card layout with a peek of the next page.
  case cardPeek(interPageSpacing: CGFloat = 12, peekWidth: CGFloat = 24)

  /// Fixed page width centered in a wider container.
  case fixedPageWidth(CGFloat)

  /// Inset rounded card pages.
  case insetCard(cornerRadius: CGFloat = 12, horizontalInset: CGFloat = 16)
}

/// Height strategy for the carousel container.
public enum FKCarouselHeightStrategy: Equatable, Sendable {
  /// Fixed point height.
  case fixed(CGFloat)

  /// Height derived from width and aspect ratio (e.g. `16.0 / 9.0`).
  case aspectRatio(CGFloat)

  /// Height driven by the current page content.
  case intrinsicFromCurrentPage
}

/// Layout and geometry configuration for ``FKCarousel``.
public struct FKCarouselLayoutConfiguration: Equatable, Sendable {
  /// Horizontal page layout mode.
  public var layoutMode: FKCarouselLayoutMode

  /// Height strategy.
  public var heightStrategy: FKCarouselHeightStrategy

  /// Spacing between pages (used by peek and inset modes).
  public var interPageSpacing: CGFloat

  /// Whether the carousel clips subviews to bounds.
  public var clipsToBounds: Bool

  /// Optional content insets applied to the collection view.
  public var contentInsets: UIEdgeInsets

  /// Whether the page indicator respects the safe area when overlaid.
  public var respectsSafeAreaForIndicator: Bool

  /// Enables seamless infinite looping when there are at least two pages.
  public var isInfiniteLoopEnabled: Bool

  /// Creates layout configuration.
  public init(
    layoutMode: FKCarouselLayoutMode = .fullPage,
    heightStrategy: FKCarouselHeightStrategy = .aspectRatio(16.0 / 9.0),
    interPageSpacing: CGFloat = 0,
    clipsToBounds: Bool = true,
    contentInsets: UIEdgeInsets = .zero,
    respectsSafeAreaForIndicator: Bool = true,
    isInfiniteLoopEnabled: Bool = false
  ) {
    self.layoutMode = layoutMode
    self.heightStrategy = heightStrategy
    self.interPageSpacing = interPageSpacing
    self.clipsToBounds = clipsToBounds
    self.contentInsets = contentInsets
    self.respectsSafeAreaForIndicator = respectsSafeAreaForIndicator
    self.isInfiniteLoopEnabled = isInfiniteLoopEnabled
  }
}
