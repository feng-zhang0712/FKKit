import UIKit

/// Optional dimmed backdrop and anchor spotlight used for coach marks and onboarding.
public struct FKCalloutBackdropStyle: Sendable, Equatable {
  /// When `true`, draws a dimmed layer behind the bubble.
  public var showsDimmedBackdrop: Bool
  /// When `true` and ``showsDimmedBackdrop`` is enabled, cuts out a rounded rect around the anchor.
  public var spotlightsAnchor: Bool
  /// Fill color for the dimmed region; `nil` uses a standard dark scrim.
  public var dimColor: UIColor?
  /// Corner radius for the anchor spotlight cutout.
  public var spotlightCornerRadius: CGFloat

  /// Creates backdrop styling.
  public init(
    showsDimmedBackdrop: Bool = false,
    spotlightsAnchor: Bool = true,
    dimColor: UIColor? = nil,
    spotlightCornerRadius: CGFloat = 8
  ) {
    self.showsDimmedBackdrop = showsDimmedBackdrop
    self.spotlightsAnchor = spotlightsAnchor
    self.dimColor = dimColor
    self.spotlightCornerRadius = spotlightCornerRadius
  }
}
