import Foundation

/// Selection policies for ``FKRadioGroup``.
public struct FKRadioGroupInteractionConfiguration: Sendable, Equatable {
  /// When `true`, tapping the selected option clears selection (requires ``allowsEmptySelection``).
  public var allowsDeselection: Bool
  /// When `true`, ``FKRadioGroup/selectedOptionID`` may be `nil`.
  public var allowsEmptySelection: Bool
  /// When `true`, disabling the selected option moves selection to the first enabled option.
  public var reselectWhenSelectedOptionDisabled: Bool
  public var duplicateIDPolicy: FKRadioGroupDuplicateIDPolicy
  public var haptic: FKSelectionControlHaptic

  public init(
    allowsDeselection: Bool = false,
    allowsEmptySelection: Bool = false,
    reselectWhenSelectedOptionDisabled: Bool = false,
    duplicateIDPolicy: FKRadioGroupDuplicateIDPolicy = .assertInDebug,
    haptic: FKSelectionControlHaptic = .none
  ) {
    self.allowsDeselection = allowsDeselection
    self.allowsEmptySelection = allowsEmptySelection
    self.reselectWhenSelectedOptionDisabled = reselectWhenSelectedOptionDisabled
    self.duplicateIDPolicy = duplicateIDPolicy
    self.haptic = haptic
  }
}
