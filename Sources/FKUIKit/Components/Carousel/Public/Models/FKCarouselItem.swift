import Foundation

/// A stable, hashable page identity for ``FKCarousel``.
public struct FKCarouselItem: Hashable, Sendable {
  /// Stable identifier across reloads (host-defined).
  public let id: String

  /// Optional VoiceOver label combined with page position announcements.
  public let accessibilityLabel: String?

  /// When `false`, page selection callbacks are suppressed and the page may appear dimmed.
  public let isInteractive: Bool

  /// Creates a carousel page item.
  public init(
    id: String,
    accessibilityLabel: String? = nil,
    isInteractive: Bool = true
  ) {
    self.id = id
    self.accessibilityLabel = accessibilityLabel
    self.isInteractive = isInteractive
  }
}
