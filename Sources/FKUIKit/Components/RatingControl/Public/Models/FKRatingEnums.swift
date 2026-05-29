import UIKit

// MARK: - Interaction

/// Whether the user can change the score.
public enum FKRatingInteractionMode: Int, Sendable, Equatable {
  /// Displays the current value; ignores touch and pan gestures.
  case readOnly
  /// Allows tap and drag to update the value.
  case interactive
}

/// Discrete increments applied after user input.
public enum FKRatingStep: Sendable, Equatable {
  /// Whole-number steps (for example `1.0` on a five-star control).
  case whole
  /// Half-step increments (for example `0.5`).
  case half
  /// Custom positive increment.
  case custom(Double)

  /// Resolved step size used for snapping and accessibility adjustments.
  public var increment: Double {
    switch self {
    case .whole:
      return 1
    case .half:
      return 0.5
    case let .custom(value):
      return max(0.01, value)
    }
  }
}

// MARK: - Icons

/// Built-in SF Symbol presets for common rating styles.
public enum FKRatingIconPreset: Int, Sendable, Equatable {
  case star
  case heart
  case thumbUp
}

/// Icon source for empty, filled, and optional half glyphs.
public enum FKRatingIconStyle: Equatable, @unchecked Sendable {
  /// Maps to system SF Symbols (`star`, `heart`, `hand.thumbsup`, and their filled variants).
  case preset(FKRatingIconPreset)
  /// Explicit SF Symbol names resolved at runtime.
  case symbols(empty: String, filled: String, half: String? = nil)
  /// Custom bitmaps supplied by the host app.
  case images(empty: UIImage, filled: UIImage, half: UIImage? = nil)
}

// MARK: - Motion & feedback

/// Optional haptic fired when the snapped value changes during interaction.
public enum FKRatingTouchHaptic: Int, Sendable, Equatable {
  case none
  case light
  case selection
}

/// Lightweight scale animation applied to items whose fill level changes.
public enum FKRatingSelectionAnimation: Int, Sendable, Equatable {
  case none
  case bounce
}

/// Placement of an optional numeric or custom caption.
public enum FKRatingLabelPlacement: Int, Sendable, Equatable {
  case none
  case trailing
  case bottom
}

/// Built-in timing for fill transitions.
public enum FKRatingTiming: Int, Sendable, Equatable {
  case `default`
  case easeOut

  func mediaTimingFunction() -> CAMediaTimingFunction {
    switch self {
    case .default:
      return CAMediaTimingFunction(name: .default)
    case .easeOut:
      return CAMediaTimingFunction(name: .easeOut)
    }
  }
}
