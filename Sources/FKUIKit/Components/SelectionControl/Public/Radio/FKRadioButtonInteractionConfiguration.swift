import Foundation

/// Touch behavior for ``FKRadioButton``.
public struct FKRadioButtonInteractionConfiguration: Sendable, Equatable {
  public var mode: FKSelectionControlInteractionMode
  /// When `true`, tapping an unselected radio selects it. Deselection of a standalone radio requires host logic or a group with ``FKRadioGroupInteractionConfiguration/allowsDeselection``.
  public var selectsOnTouch: Bool
  public var haptic: FKSelectionControlHaptic

  public init(
    mode: FKSelectionControlInteractionMode = .interactive,
    selectsOnTouch: Bool = true,
    haptic: FKSelectionControlHaptic = .none
  ) {
    self.mode = mode
    self.selectsOnTouch = selectsOnTouch
    self.haptic = haptic
  }
}
