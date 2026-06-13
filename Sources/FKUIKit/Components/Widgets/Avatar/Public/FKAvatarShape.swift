import CoreGraphics

/// Clipping shape for avatar content.
public enum FKAvatarShape: Sendable, Equatable {
  /// Circular mask (default).
  case circle
  /// Continuous corner curve squircle.
  case squircle(cornerRadius: CGFloat)
  /// Fixed corner radius rectangle.
  case roundedRectangle(cornerRadius: CGFloat)
}
