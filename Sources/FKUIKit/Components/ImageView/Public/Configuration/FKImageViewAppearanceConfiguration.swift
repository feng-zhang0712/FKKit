import UIKit

/// Corner rounding strategy for ``FKImageView``.
public enum FKImageViewCornerStyle: Equatable, Sendable {
  /// Square corners.
  case none
  /// Uniform corner radius in points.
  case fixed(CGFloat)
  /// Pill / circle based on `min(width, height) / 2`.
  case capsule
  /// Partial corner rounding.
  case perCorner(UIRectCorner, radius: CGFloat)
}

/// Animated transition applied when a load succeeds.
public enum FKImageViewSuccessTransition: Equatable, Sendable {
  /// Immediate image swap.
  case none
  /// Cross-dissolve via `UIView.transition`.
  case crossDissolve(duration: TimeInterval)
  /// Alpha fade-in on the image view.
  case fadeIn(duration: TimeInterval)
}

/// Visual styling for ``FKImageView`` content and chrome.
public struct FKImageViewAppearanceConfiguration: @unchecked Sendable {
  /// Corner rounding applied to the clipped content container.
  public var cornerStyle: FKImageViewCornerStyle
  /// Optional stroke around the clipped content.
  public var borderStyle: FKLayerBorderStyle
  /// Optional drop shadow on the outer container.
  public var shadowStyle: FKLayerShadowStyle
  /// Fill visible in letterboxed regions when ``contentMode`` is aspect-fit.
  public var backgroundColor: UIColor?
  /// Default `UIImageView` content mode.
  public var contentMode: UIView.ContentMode
  /// Success transition; reduced motion forces ``FKImageViewSuccessTransition/none``.
  public var successTransition: FKImageViewSuccessTransition
  /// Template tint when ``rendersAsTemplate`` is `true`.
  public var tintColor: UIColor?
  /// When `true`, sets `UIImage.renderingMode` to `.alwaysTemplate`.
  public var rendersAsTemplate: Bool
  /// Highlight dimming for tappable images; enables press alpha feedback (same effect as ``FKImageViewInteractionConfiguration/highlightOnPress``).
  public var adjustsImageWhenHighlighted: Bool
  /// Highlight alpha when pressed and highlight feedback is active.
  public var highlightedAlpha: CGFloat

  /// Creates appearance defaults.
  public init(
    cornerStyle: FKImageViewCornerStyle = .none,
    borderStyle: FKLayerBorderStyle = .none,
    shadowStyle: FKLayerShadowStyle = .none,
    backgroundColor: UIColor? = nil,
    contentMode: UIView.ContentMode = .scaleAspectFill,
    successTransition: FKImageViewSuccessTransition = .crossDissolve(duration: 0.2),
    tintColor: UIColor? = nil,
    rendersAsTemplate: Bool = false,
    adjustsImageWhenHighlighted: Bool = false,
    highlightedAlpha: CGFloat = 0.7
  ) {
    self.cornerStyle = cornerStyle
    self.borderStyle = borderStyle
    self.shadowStyle = shadowStyle
    self.backgroundColor = backgroundColor
    self.contentMode = contentMode
    self.successTransition = successTransition
    self.tintColor = tintColor
    self.rendersAsTemplate = rendersAsTemplate
    self.adjustsImageWhenHighlighted = adjustsImageWhenHighlighted
    self.highlightedAlpha = highlightedAlpha
  }
}
