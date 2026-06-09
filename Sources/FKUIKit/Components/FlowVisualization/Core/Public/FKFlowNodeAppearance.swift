import UIKit

/// Per-state node chrome resolved from ``FKFlowAppearanceConfiguration``.
public struct FKFlowNodeAppearance: @unchecked Sendable, Equatable {
  /// Node fill color.
  public var fillColor: UIColor
  /// Border stroke around the node.
  public var border: FKLayerBorderStyle
  /// Tint applied to template icons and number labels.
  public var iconTint: UIColor
  /// Optional drop shadow.
  public var shadow: FKLayerShadowStyle?

  public init(
    fillColor: UIColor = .systemBackground,
    border: FKLayerBorderStyle = .none,
    iconTint: UIColor = .label,
    shadow: FKLayerShadowStyle? = nil
  ) {
    self.fillColor = fillColor
    self.border = border
    self.iconTint = iconTint
    self.shadow = shadow
  }
}
