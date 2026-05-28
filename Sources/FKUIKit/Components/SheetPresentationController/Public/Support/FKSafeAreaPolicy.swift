import UIKit

/// Defines whether safe area is respected by container bounds or only by inner content.
public enum FKSafeAreaPolicy: Equatable, Sendable {
  /// Container edges can touch screen edges while content is inset inside the wrapper.
  ///
  /// The wrapper reaches the physical bottom edge; the content container is shortened by the home-indicator inset.
  case contentRespectsSafeArea
  /// Container itself keeps spacing from safe area boundaries.
  ///
  /// Use this when the presented chrome itself must avoid notches/home-indicator regions.
  case containerRespectsSafeArea
  /// Wrapper and content container share the same frame to the physical bottom edge.
  ///
  /// Use when inner content (for example a table view) applies `contentInset` for the home indicator.
  case shellExtendsToScreenBottomEdge
}

public extension FKSafeAreaPolicy {
  /// Whether the presentation shell is positioned flush with the container bottom edge.
  var positionsShellAtContainerBottomEdge: Bool {
    switch self {
    case .contentRespectsSafeArea, .shellExtendsToScreenBottomEdge:
      return true
    case .containerRespectsSafeArea:
      return false
    }
  }
}
