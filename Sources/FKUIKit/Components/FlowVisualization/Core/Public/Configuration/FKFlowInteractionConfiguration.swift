import UIKit

/// Selection, expansion, and haptic behavior shared by flow controls.
public struct FKFlowInteractionConfiguration: Sendable, Equatable {
  /// Enables tap selection when `true`.
  public var allowsSelection: Bool
  /// States that may be selected by the user.
  public var selectableStates: Set<FKFlowStepState>
  /// Timeline-only: toggles caption expansion on tap.
  public var allowsExpansion: Bool
  /// Fires a light impact haptic on successful selection.
  public var hapticOnSelect: Bool
  /// Minimum hit target centered on each node (HIG recommends 44×44).
  public var minimumTouchTargetSize: CGSize
  /// Opacity multiplier for disabled steps.
  public var disabledAlpha: CGFloat

  public init(
    allowsSelection: Bool = false,
    selectableStates: Set<FKFlowStepState> = [.completed],
    allowsExpansion: Bool = false,
    hapticOnSelect: Bool = false,
    minimumTouchTargetSize: CGSize = CGSize(width: 44, height: 44),
    disabledAlpha: CGFloat = 0.45
  ) {
    self.allowsSelection = allowsSelection
    self.selectableStates = selectableStates
    self.allowsExpansion = allowsExpansion
    self.hapticOnSelect = hapticOnSelect
    self.minimumTouchTargetSize = CGSize(
      width: max(24, minimumTouchTargetSize.width),
      height: max(24, minimumTouchTargetSize.height)
    )
    self.disabledAlpha = min(max(0.1, disabledAlpha), 1)
  }
}
