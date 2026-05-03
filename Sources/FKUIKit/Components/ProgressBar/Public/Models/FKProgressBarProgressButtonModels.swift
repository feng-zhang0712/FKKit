import UIKit

// MARK: - Progress-as-button interaction

/// Whether the control behaves as a read-only indicator or as a tappable button.
public enum FKProgressBarInteractionMode: Int, Sendable {
  /// Non-interactive: touches pass through (``UIView/isUserInteractionEnabled`` is `false`).
  case indicator
  /// Interactive: uses ``UIControl`` tracking and sends ``UIControl/Event/primaryActionTriggered`` and ``UIControl/Event/touchUpInside`` on successful taps.
  case button
}

/// How the visible label text is chosen when ``FKProgressBarLabelConfiguration/labelPlacement`` is not ``FKProgressBarLabelPlacement/none``.
public enum FKProgressBarLabelContentMode: Int, Sendable {
  /// Formatted from ``FKProgressBar/progress`` using ``FKProgressBarLabelConfiguration/labelFormat`` (legacy behavior).
  case formattedProgress
  /// Always shows ``FKProgressBarLabelConfiguration/customTitle`` (progress is visible only in the fill).
  case customTitleOnly
  /// Shows ``FKProgressBarLabelConfiguration/customTitle`` while determinate ``progress`` is zero and ``FKProgressBar/isIndeterminate`` is `false`; otherwise shows the formatted progress string.
  case customTitleWhenIdle
  /// Two lines: ``FKProgressBarLabelConfiguration/customTitle`` on the first line and formatted progress on the second (e.g. action title + percent).
  case customTitleWithProgressSubtitle
}

/// Optional haptics for ``FKProgressBarInteractionMode/button``.
public enum FKProgressBarTouchHaptic: Int, Sendable {
  case none
  case lightImpactOnTouchDown
  case selectionChangedOnTouchDown
}
