import Foundation

/// Touch and toggle behavior for ``FKCheckbox``.
public struct FKCheckboxInteractionConfiguration: Sendable, Equatable {
  public var mode: FKSelectionControlInteractionMode
  public var togglesOnTouch: Bool
  public var indeterminateTapBehavior: FKCheckboxIndeterminateTapBehavior
  /// When `false`, indeterminate writes clamp to ``FKCheckboxState/unchecked``.
  public var allowsIndeterminate: Bool
  /// When `false` (default), tapping a link only fires ``FKCheckbox/onLinkActivated``.
  public var linkTapTogglesCheckbox: Bool
  public var haptic: FKSelectionControlHaptic

  public init(
    mode: FKSelectionControlInteractionMode = .interactive,
    togglesOnTouch: Bool = true,
    indeterminateTapBehavior: FKCheckboxIndeterminateTapBehavior = .promoteToChecked,
    allowsIndeterminate: Bool = true,
    linkTapTogglesCheckbox: Bool = false,
    haptic: FKSelectionControlHaptic = .none
  ) {
    self.mode = mode
    self.togglesOnTouch = togglesOnTouch
    self.indeterminateTapBehavior = indeterminateTapBehavior
    self.allowsIndeterminate = allowsIndeterminate
    self.linkTapTogglesCheckbox = linkTapTogglesCheckbox
    self.haptic = haptic
  }
}
