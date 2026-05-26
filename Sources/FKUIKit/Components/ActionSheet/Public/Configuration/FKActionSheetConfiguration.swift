import UIKit

/// Complete description of an action sheet instance.
public struct FKActionSheetConfiguration {
  /// Optional header content (text or custom view).
  public var header: FKActionSheetHeaderContent?
  /// Primary action groups.
  public var sections: [FKActionSheetSection]
  /// Optional cancel row rendered in a separate group (HIG separation).
  public var cancelAction: FKActionSheetAction?
  /// Row and header styling.
  public var appearance: FKActionSheetAppearance
  /// Modal presentation tuning (backdrop, sizing cap, dismiss gestures).
  public var presentation: FKActionSheetPresentationConfiguration
  /// When `true`, selecting a non-cancel action dismisses the sheet after invoking its handler policy.
  public var dismissesAfterActionSelection: Bool
  /// When action handlers run relative to dismissal.
  public var handlerTiming: FKActionSheetHandlerTiming
  /// Optional single-selection handling for checkmark rows.
  public var selection: FKActionSheetSelectionConfiguration
  /// Optional haptic feedback (disabled by default).
  public var haptics: FKActionSheetHapticsConfiguration
  /// Lifecycle and selection callbacks.
  public var hooks: FKActionSheetLifecycleHooks

  /// Creates a configuration.
  public init(
    header: FKActionSheetHeaderContent? = nil,
    sections: [FKActionSheetSection] = [],
    cancelAction: FKActionSheetAction? = nil,
    appearance: FKActionSheetAppearance? = nil,
    appearancePreset: FKActionSheetAppearancePreset? = nil,
    presentation: FKActionSheetPresentationConfiguration = .default,
    dismissesAfterActionSelection: Bool = true,
    handlerTiming: FKActionSheetHandlerTiming = .beforeDismiss,
    selection: FKActionSheetSelectionConfiguration = .init(),
    haptics: FKActionSheetHapticsConfiguration = .init(),
    hooks: FKActionSheetLifecycleHooks = .init()
  ) {
    self.header = header
    self.sections = sections
    self.cancelAction = cancelAction
    if let appearance {
      self.appearance = appearance
    } else if let appearancePreset {
      self.appearance = .preset(appearancePreset)
    } else {
      self.appearance = .preset(.system)
    }
    self.presentation = presentation
    self.dismissesAfterActionSelection = dismissesAfterActionSelection
    self.handlerTiming = handlerTiming
    self.selection = selection
    self.haptics = haptics
    self.hooks = hooks
  }

  /// Flattens all configured actions (sections + cancel) for validation and lookup.
  public var allActions: [FKActionSheetAction] {
    sections.flatMap(\.actions) + (cancelAction.map { [$0] } ?? [])
  }
}

public extension FKActionSheetConfiguration {
  /// Creates a configuration with a built-in text header.
  init(
    header: FKActionSheetHeader?,
    sections: [FKActionSheetSection] = [],
    cancelAction: FKActionSheetAction? = nil,
    appearance: FKActionSheetAppearance? = nil,
    appearancePreset: FKActionSheetAppearancePreset? = nil,
    presentation: FKActionSheetPresentationConfiguration = .default,
    dismissesAfterActionSelection: Bool = true,
    handlerTiming: FKActionSheetHandlerTiming = .beforeDismiss,
    selection: FKActionSheetSelectionConfiguration = .init(),
    haptics: FKActionSheetHapticsConfiguration = .init(),
    hooks: FKActionSheetLifecycleHooks = .init()
  ) {
    self.init(
      header: header.map { .text($0) },
      sections: sections,
      cancelAction: cancelAction,
      appearance: appearance,
      appearancePreset: appearancePreset,
      presentation: presentation,
      dismissesAfterActionSelection: dismissesAfterActionSelection,
      handlerTiming: handlerTiming,
      selection: selection,
      haptics: haptics,
      hooks: hooks
    )
  }
}
