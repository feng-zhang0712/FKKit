import UIKit

enum FKFlowLayoutMetrics {
  static func nodeDiameter(
    base: FKFlowNodeSize,
    scalesWithContentSize: Bool,
    traitCollection: UITraitCollection?
  ) -> CGFloat {
    var diameter = base.diameter
    guard scalesWithContentSize, let traitCollection else { return diameter }
    let category = traitCollection.preferredContentSizeCategory
    if category.isAccessibilityCategory {
      diameter *= 1.12
    } else if category >= .extraExtraExtraLarge {
      diameter *= 1.06
    }
    return diameter
  }

  static func densitySpacing(_ density: FKFlowDensity, axis: NSLayoutConstraint.Axis) -> CGFloat {
    switch (density, axis) {
    case (.regular, .horizontal): return 12
    case (.compact, .horizontal): return 8
    case (.spacious, .horizontal): return 16
    case (.regular, .vertical): return 16
    case (.compact, .vertical): return 10
    case (.spacious, .vertical): return 24
    default: return 12
    }
  }

  static func labelSpacing(_ density: FKFlowDensity) -> CGFloat {
    switch density {
    case .regular: return 6
    case .compact: return 4
    case .spacious: return 10
    }
  }

  static func contentInsets(for density: FKFlowDensity, embedded: Bool) -> UIEdgeInsets {
    if embedded {
      return UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
    }
    switch density {
    case .regular: return UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    case .compact: return UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
    case .spacious: return UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
    }
  }
}
