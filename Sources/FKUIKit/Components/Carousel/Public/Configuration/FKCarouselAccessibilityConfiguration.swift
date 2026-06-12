import Foundation

/// Accessibility configuration.
public struct FKCarouselAccessibilityConfiguration: Equatable, Sendable {
  /// Enables VoiceOver three-finger scroll page changes.
  public var supportsAccessibilityScroll: Bool

  /// Announces page changes via `UIAccessibility.post(notification: .pageScrolled, ...)`.
  public var announcesPageChanges: Bool

  /// Creates accessibility configuration.
  public init(
    supportsAccessibilityScroll: Bool = true,
    announcesPageChanges: Bool = true
  ) {
    self.supportsAccessibilityScroll = supportsAccessibilityScroll
    self.announcesPageChanges = announcesPageChanges
  }
}
