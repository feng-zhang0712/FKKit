import Foundation

// MARK: - Custom accessory placement

/// Positions a custom accessory view (e.g. Lottie) relative to the image slot and text stack.
public enum FKEmptyStateCustomPlacement: Equatable, Sendable {
  /// Shows only the custom view in the illustration row (built-in image hidden).
  case replaceImage
  /// Custom view above `UIImageView`.
  case aboveImage
  /// Custom view between image and title.
  case belowImage
  /// Custom view after description, before spinner/button slot (spinner only in loading phase).
  case belowDescription
}

// MARK: - Content alignment

/// Vertical placement strategy for the placeholder content inside the host view.
public enum FKEmptyStateContentAlignment: Equatable, Sendable {
  /// Centers content vertically in the safe area.
  case center
  /// Pins content to the top safe area with a configurable offset.
  case top
}
