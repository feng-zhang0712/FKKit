import UIKit

/// Capsule height presets shared by ``FKChip`` and ``FKTag``.
public enum FKChipSize: Sendable, Equatable {
  /// 22 pt — dense tags.
  case xs
  /// 30 pt — card tags and compact chips.
  case s
  /// 36 pt — default interactive chips.
  case m
  /// Custom height (clamped to at least 20 pt).
  case custom(height: CGFloat)

  /// Resolved capsule height in points.
  public var height: CGFloat {
    switch self {
    case .xs: 22
    case .s: 30
    case .m: 36
    case .custom(let height):
      max(20, height)
    }
  }
}

/// Interaction semantics for ``FKChip``.
public enum FKChipMode: Sendable, Equatable {
  /// Toggle selected on tap; emits ``UIControl/Event/valueChanged``.
  case filter
  /// Input token; optional remove button; no persistent selected fill.
  case input
  /// One-shot suggestion; emits ``UIControl/Event/primaryActionTriggered`` without toggling selection.
  case suggestion
  /// Mutually exclusive selection when used inside a group; toggles selected locally otherwise.
  case choice
}

/// Visual style token for ``FKTag`` (marketing/metadata — not workflow status).
public enum FKTagVariant: Sendable, Equatable {
  case neutral
  case brand
  case success
  case warning
  case error
  case outline
  case custom(FKTagCustomVariant)
}

/// Custom tag colors when ``FKTagVariant/custom(_:)`` is used.
public struct FKTagCustomVariant: @unchecked Sendable, Equatable {
  public var backgroundColor: UIColor
  public var foregroundColor: UIColor
  public var borderColor: UIColor?
  public var borderWidth: CGFloat

  public init(
    backgroundColor: UIColor,
    foregroundColor: UIColor,
    borderColor: UIColor? = nil,
    borderWidth: CGFloat = 0
  ) {
    self.backgroundColor = backgroundColor
    self.foregroundColor = foregroundColor
    self.borderColor = borderColor
    self.borderWidth = borderWidth
  }
}

extension FKTagCustomVariant {
  public static func == (lhs: FKTagCustomVariant, rhs: FKTagCustomVariant) -> Bool {
    lhs.borderWidth == rhs.borderWidth
  }
}

/// Group selection orchestration mode.
public enum FKChipGroupSelectionMode: Sendable, Equatable {
  case none
  case single
  case multiple(max: Int?)
}

/// Behavior when ``FKChipGroupSelectionMode/multiple(max:)`` reaches capacity.
public enum FKChipGroupOverflowBehavior: Sendable, Equatable {
  /// Ignore taps on unselected chips when at capacity.
  case ignoreTap
  /// Notify via ``FKChipGroup/onSelectionLimitReached`` but do not select.
  case notify
}

/// Layout strategy for ``FKChipGroup``.
public enum FKChipGroupLayoutMode: Sendable, Equatable {
  case flow(wrap: Bool = true)
  case horizontalScroll
}
