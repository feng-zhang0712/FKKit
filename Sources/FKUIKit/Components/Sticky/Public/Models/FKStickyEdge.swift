import CoreGraphics
import Foundation

/// Edge of the scroll viewport used as the sticky pin line.
public enum FKStickyEdge: String, Sendable, Equatable, CaseIterable {
  /// Pins under the top inset (`adjustedContentInset.top` + sticky inset).
  case top
  /// Pins above the bottom inset (`adjustedContentInset.bottom` + sticky inset).
  case bottom
}
