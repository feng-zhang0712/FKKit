import UIKit

public extension FKActionSheetAction {
  /// Creates a custom row using a view builder. Attach your model via ``metadata`` or capture it in the builder closure.
  static func custom(
    id: UUID = UUID(),
    reuseIdentifier: String = "FKActionSheetCustomRow",
    preferredHeight: CGFloat? = nil,
    isSelectable: Bool = true,
    isEnabled: Bool = true,
    style: Style = .default,
    metadata: FKActionSheetMetadata? = nil,
    accessibilityLabel: String? = nil,
    accessibilityHint: String? = nil,
    dismissesSheetWhenSelected: Bool? = nil,
    handler: (@MainActor () -> Void)? = nil,
    build: @escaping @MainActor (FKActionSheetRowBuildContext) -> UIView,
    update: (@MainActor (FKActionSheetRowBuildContext, UIView) -> Void)? = nil
  ) -> FKActionSheetAction {
    let provider = FKActionSheetCustomRowProvider(build: build, update: update)
    let customRow = FKActionSheetCustomRow(
      id: id,
      reuseIdentifier: reuseIdentifier,
      preferredHeight: preferredHeight,
      isSelectable: isSelectable,
      provider: provider
    )
    return FKActionSheetAction(
      id: id,
      customRow: customRow,
      style: style,
      isEnabled: isEnabled,
      dismissesSheetWhenSelected: dismissesSheetWhenSelected,
      metadata: metadata,
      accessibilityLabel: accessibilityLabel,
      accessibilityHint: accessibilityHint,
      handler: handler
    )
  }
}

public extension FKActionSheetConfiguration {
  /// Creates a configuration with a custom header view.
  init(
    customHeader: FKActionSheetCustomHeader,
    sections: [FKActionSheetSection] = [],
    cancelAction: FKActionSheetAction? = nil,
    appearance: FKActionSheetAppearance? = nil,
    appearancePreset: FKActionSheetAppearancePreset? = nil,
    presentation: FKActionSheetPresentationConfiguration = .default,
    presentationTransform: FKActionSheetPresentationConfiguration.ConfigurationTransform? = nil,
    dismissesAfterActionSelection: Bool = true,
    handlerTiming: FKActionSheetHandlerTiming = .beforeDismiss,
    selection: FKActionSheetSelectionConfiguration = .init(),
    haptics: FKActionSheetHapticsConfiguration = .init(),
    hooks: FKActionSheetLifecycleHooks = .init(),
    delegate: FKActionSheetDelegate? = nil
  ) {
    self.init(
      header: .custom(customHeader),
      sections: sections,
      cancelAction: cancelAction,
      appearance: appearance,
      appearancePreset: appearancePreset,
      presentation: presentation,
      presentationTransform: presentationTransform,
      dismissesAfterActionSelection: dismissesAfterActionSelection,
      handlerTiming: handlerTiming,
      selection: selection,
      haptics: haptics,
      hooks: hooks,
      delegate: delegate
    )
  }
}

public extension FKActionSheetBuilder {
  /// Builds a custom header provider with a one-line builder closure.
  func customHeader(
    preferredHeight: CGFloat? = nil,
    accessibilityLabel: String? = nil,
    build: @escaping @MainActor (FKActionSheetHeaderBuildContext) -> UIView,
    update: (@MainActor (FKActionSheetHeaderBuildContext, UIView) -> Void)? = nil
  ) -> Self {
    let provider = FKActionSheetCustomHeaderProvider(build: build, update: update)
    let header = FKActionSheetCustomHeader(
      preferredHeight: preferredHeight,
      accessibilityLabel: accessibilityLabel,
      provider: provider
    )
    return customHeader(header)
  }
}
