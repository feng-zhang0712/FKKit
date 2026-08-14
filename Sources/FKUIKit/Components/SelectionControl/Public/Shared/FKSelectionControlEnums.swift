import Foundation

/// Whether the control accepts toggle taps.
public enum FKSelectionControlInteractionMode: Sendable, Equatable {
  /// User taps toggle selection state.
  case interactive
  /// Renders state; ignores toggle taps (attributed links may still fire).
  case readOnly
}

/// Optional haptic feedback when selection changes.
public enum FKSelectionControlHaptic: Sendable, Equatable {
  case none
  case light
  case selection
}

/// Animation applied when the selection glyph or fill changes.
public enum FKSelectionControlSelectionAnimation: Sendable, Equatable {
  /// Cross-dissolve between indicator presentations (default).
  case crossfade
  /// Brief scale pop on the indicator.
  case scalePop
  /// Instant update.
  case none
}

/// How an indeterminate checkbox responds to a tap.
public enum FKCheckboxIndeterminateTapBehavior: Sendable, Equatable {
  /// Advances to checked (default).
  case promoteToChecked
  /// Clears to unchecked.
  case promoteToUnchecked
  /// Cycles unchecked → checked → indeterminate → unchecked.
  case cycle
}

/// Radio selected fill style. v1 ships ``ringAndDot`` only (design-aligned outer ring + inner dot).
public enum FKRadioSelectedFillStyle: Sendable, Equatable {
  /// Colored outer ring with a same-color solid inner dot and a clear gap between them.
  case ringAndDot
}

/// Policy when ``FKRadioGroup`` options contain duplicate ids.
public enum FKRadioGroupDuplicateIDPolicy: Sendable, Equatable {
  /// Assert in DEBUG and keep the first occurrence.
  case assertInDebug
  /// Keep the first occurrence silently.
  case keepFirst
}

/// Visual layout style for ``FKRadioGroup``.
public enum FKRadioGroupLayoutStyle: Sendable, Equatable {
  /// Stacked rows without card chrome.
  case plain
  /// Rounded card with separators (design default).
  case insetGrouped
  /// Horizontal row of options; overflows may scroll.
  case horizontal
}
