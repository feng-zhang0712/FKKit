import UIKit

/// Resolves ``FKSelectionControlTint`` into concrete colors for Light / Dark Mode.
enum FKSelectionControlTintResolver {
  static func color(for tint: FKSelectionControlTint) -> UIColor {
    switch tint {
    case .blue:
      return .systemBlue
    case .green:
      return .systemGreen
    case .red:
      return .systemRed
    case .orange:
      return .systemOrange
    case .purple:
      return .systemPurple
    case let .custom(color):
      return color
    }
  }

  /// Softened tint for Disabled+On presentations.
  static func disabledOnColor(for tint: FKSelectionControlTint, alpha: CGFloat) -> UIColor {
    color(for: tint).withAlphaComponent(min(max(alpha, 0.2), 1))
  }

  static var defaultUncheckedBorder: UIColor {
    UIColor { traits in
      traits.userInterfaceStyle == .dark
        ? UIColor.tertiaryLabel
        : UIColor.separator
    }
  }

  static var disabledUncheckedBorder: UIColor {
    UIColor.quaternaryLabel
  }
}
