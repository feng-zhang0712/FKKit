import Foundation

/// Horizontal edge fade overlay for scrollable tab strips.
public struct FKTabBarScrollEdgeFade: Equatable, Sendable {
  /// Enables leading/trailing fade overlays when ``FKTabBarLayoutConfiguration/isScrollable`` is `true`.
  public var isEnabled: Bool
  /// Fade gradient width on each edge.
  public var width: CGFloat

  /// Creates scroll edge fade options.
  public init(isEnabled: Bool = false, width: CGFloat = 20) {
    self.isEnabled = isEnabled
    self.width = max(0, width)
  }
}
