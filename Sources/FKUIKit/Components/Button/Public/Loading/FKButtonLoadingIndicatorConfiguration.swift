import UIKit

/// Spinner appearance while ``FKButton/setLoading(_:presentation:)`` is active.
public struct FKButtonLoadingIndicatorConfiguration: Equatable, Sendable {
  /// Passed to ``UIActivityIndicatorView/style``.
  public var style: UIActivityIndicatorView.Style
  /// Uniform scale applied to the built-in activity indicator (`1` = system default).
  public var scale: CGFloat
  /// Tint for the built-in activity indicator. When `nil`, the system default tint is used.
  public var color: UIColor?

  /// Creates loading-indicator options.
  public init(
    style: UIActivityIndicatorView.Style = .medium,
    scale: CGFloat = 1,
    color: UIColor? = nil
  ) {
    self.style = style
    self.scale = max(0.5, min(3, scale))
    self.color = color
  }

  /// System default spinner.
  public static let `default` = FKButtonLoadingIndicatorConfiguration()
}
