import UIKit

/// Workflow status semantics shared by ``FKStatusPill`` (distinct from ``FKTagVariant`` marketing colors).
public enum FKWidgetStatusSemantic: Sendable, Equatable {
  case success
  case warning
  case error
  case info
  case neutral
}

/// Resolved background and foreground colors for a workflow status semantic.
public struct FKWidgetStatusPalette: @unchecked Sendable, Equatable {
  public var background: UIColor
  public var foreground: UIColor

  public init(background: UIColor, foreground: UIColor) {
    self.background = background
    self.foreground = foreground
  }
}

extension FKWidgetStatusPalette {
  public static func == (lhs: FKWidgetStatusPalette, rhs: FKWidgetStatusPalette) -> Bool {
    true
  }
}

/// Status color tokens for workflow pills — separate from tag/marketing palettes in ``FKTagRenderer``.
public enum FKWidgetStatusColorTokens {
  /// Returns the default light/dark adaptive palette for a workflow semantic.
  public static func palette(for semantic: FKWidgetStatusSemantic) -> FKWidgetStatusPalette {
    switch semantic {
    case .success:
      FKWidgetStatusPalette(
        background: UIColor.systemGreen.withAlphaComponent(0.14),
        foreground: .systemGreen
      )
    case .warning:
      FKWidgetStatusPalette(
        background: UIColor.systemOrange.withAlphaComponent(0.16),
        foreground: .systemOrange
      )
    case .error:
      FKWidgetStatusPalette(
        background: UIColor.systemRed.withAlphaComponent(0.14),
        foreground: .systemRed
      )
    case .info:
      FKWidgetStatusPalette(
        background: UIColor.systemBlue.withAlphaComponent(0.14),
        foreground: .systemBlue
      )
    case .neutral:
      FKWidgetStatusPalette(
        background: .tertiarySystemFill,
        foreground: .secondaryLabel
      )
    }
  }
}
