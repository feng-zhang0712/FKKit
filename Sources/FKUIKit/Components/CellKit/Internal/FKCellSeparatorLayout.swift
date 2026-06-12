import UIKit

/// Applies bottom separators using ``FKDivider`` according to ``FKCellSeparatorPolicy``.
@MainActor
enum FKCellSeparatorLayout {
  static func makeDivider() -> FKDivider {
    var configuration = FKDivider.defaultConfiguration
    configuration.color = .separator
    configuration.isPixelPerfect = true
    return FKDivider(configuration: configuration)
  }

  static func updateVisibility(
    divider: FKDivider,
    policy: FKCellSeparatorPolicy,
    isLastInSection: Bool
  ) {
    switch policy {
    case .automatic, .insetFromLeadingContent, .fullWidth:
      divider.isHidden = isLastInSection
    case .none:
      divider.isHidden = true
    }
  }

  static func leadingInset(
    for policy: FKCellSeparatorPolicy,
    contentStack: FKCellContentStack,
    appearance: FKCellAppearanceConfiguration
  ) -> CGFloat {
    switch policy {
    case .fullWidth:
      return 0
    case .insetFromLeadingContent:
      return appearance.contentInsets.left
    case .automatic, .none:
      return appearance.contentInsets.left
    }
  }
}
