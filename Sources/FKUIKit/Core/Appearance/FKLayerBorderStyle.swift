import UIKit

/// Shared model for a `CALayer` stroke drawn via `borderWidth` / `borderColor`.
public enum FKLayerBorderStyle: Equatable, Hashable {
  case none
  case custom(color: UIColor, width: CGFloat)
}

extension CALayer {
  func fk_applyBorder(_ style: FKLayerBorderStyle) {
    switch style {
    case .none:
      borderWidth = 0
      borderColor = nil
    case .custom(let color, let width):
      borderColor = color.cgColor
      borderWidth = width
    }
  }
}
