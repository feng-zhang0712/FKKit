import UIKit

public extension FKActionSheetConfiguration {
  /// Creates a configuration that presents only the loading body (and optional cancel row).
  static func loading(
    _ content: FKActionSheetLoadingContent = .standard(FKActionSheetStandardLoadingContent()),
    preferredPanelHeight: CGFloat = 180,
    contentInsets: NSDirectionalEdgeInsets = .init(top: 16, leading: 24, bottom: 16, trailing: 24),
    showsCancelWhileLoading: Bool = true,
    cancelAction: FKActionSheetAction? = FKActionSheetAction(title: "Cancel", style: .cancel),
    header: FKActionSheetHeaderContent? = nil,
    appearance: FKActionSheetAppearance? = nil,
    appearancePreset: FKActionSheetAppearancePreset? = nil,
    presentation: FKActionSheetPresentationConfiguration = .default,
    hooks: FKActionSheetLifecycleHooks = .init()
  ) -> FKActionSheetConfiguration {
    FKActionSheetConfiguration(
      header: header,
      sections: [],
      cancelAction: cancelAction,
      appearance: appearance,
      appearancePreset: appearancePreset,
      presentation: presentation,
      hooks: hooks,
      contentMode: .loading(
        FKActionSheetLoadingConfiguration(
          content: content,
          preferredPanelHeight: preferredPanelHeight,
          contentInsets: contentInsets,
          showsCancelWhileLoading: showsCancelWhileLoading
        )
      )
    )
  }

  /// Returns a copy configured to show action rows instead of the loading body.
  func finishingLoading() -> FKActionSheetConfiguration {
    var copy = self
    copy.contentMode = .actions
    return copy
  }

  /// Returns an action-mode configuration that keeps presentation, appearance, hooks, and related
  /// settings from `base`, and copies `header`, `sections`, and `cancelAction` from `content`.
  func finishingLoading(mergingContentFrom content: FKActionSheetConfiguration) -> FKActionSheetConfiguration {
    var merged = finishingLoading()
    merged.header = content.header
    merged.sections = content.sections
    if let cancelAction = content.cancelAction {
      merged.cancelAction = cancelAction
    }
    return merged
  }
}

public extension FKActionSheet {
  /// Replaces the visible configuration with a loading presentation.
  ///
  /// Existing sections are cleared; call ``finishLoading(configuration:)`` or ``reload(configuration:)``
  /// with ``FKActionSheetContentMode/actions`` when data is ready.
  @discardableResult
  func setLoading(_ loadingConfiguration: FKActionSheetLoadingConfiguration) -> Bool {
    var config = configuration
    config.contentMode = .loading(loadingConfiguration)
    config.sections = []
    return reload(configuration: config)
  }

  /// Transitions from loading to action content, preserving the sheet's current presentation,
  /// appearance, hooks, selection, and handler settings.
  ///
  /// Only `header`, `sections`, and `cancelAction` are taken from `content`.
  @discardableResult
  func finishLoading(_ content: FKActionSheetConfiguration) -> Bool {
    reload(configuration: configuration.finishingLoading(mergingContentFrom: content))
  }

  /// Transitions from loading to action content using the supplied rows.
  ///
  /// When `cancelAction` is `nil`, the sheet keeps its existing cancel row.
  @discardableResult
  func finishLoading(
    sections: [FKActionSheetSection],
    header: FKActionSheetHeaderContent? = nil,
    cancelAction: FKActionSheetAction? = nil
  ) -> Bool {
    var content = FKActionSheetConfiguration(sections: sections)
    content.header = header
    content.cancelAction = cancelAction ?? configuration.cancelAction
    return finishLoading(content)
  }

  /// Transitions from loading to action content after mutating a copy of the current configuration.
  @discardableResult
  func finishLoading(updating update: (inout FKActionSheetConfiguration) -> Void) -> Bool {
    var config = configuration.finishingLoading()
    update(&config)
    return reload(configuration: config)
  }
}
