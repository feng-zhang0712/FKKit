import UIKit

/// Fluent builder for ``FKActionSheetConfiguration``.
@MainActor
public struct FKActionSheetBuilder {
  private var configuration = FKActionSheetConfiguration()

  /// Creates an empty builder.
  public init() {}

  /// Sets a built-in text header block.
  public func header(title: String? = nil, message: String? = nil) -> Self {
    var copy = self
    copy.configuration.header = .text(FKActionSheetHeader(title: title, message: message))
    return copy
  }

  /// Sets a custom header view.
  public func customHeader(_ header: FKActionSheetCustomHeader) -> Self {
    var copy = self
    copy.configuration.header = .custom(header)
    return copy
  }

  /// Sets header content explicitly.
  public func headerContent(_ header: FKActionSheetHeaderContent?) -> Self {
    var copy = self
    copy.configuration.header = header
    return copy
  }

  /// Replaces action sections.
  public func sections(_ sections: [FKActionSheetSection]) -> Self {
    var copy = self
    copy.configuration.sections = sections
    return copy
  }

  /// Appends one section.
  public func addSection(title: String? = nil, actions: [FKActionSheetAction]) -> Self {
    var copy = self
    copy.configuration.sections.append(FKActionSheetSection(title: title, actions: actions))
    return copy
  }

  /// Sets the separated cancel row.
  public func cancelAction(_ action: FKActionSheetAction?) -> Self {
    var copy = self
    copy.configuration.cancelAction = action
    return copy
  }

  /// Sets appearance.
  public func appearance(_ appearance: FKActionSheetAppearance) -> Self {
    var copy = self
    copy.configuration.appearance = appearance
    return copy
  }

  /// Sets appearance from a preset.
  public func appearancePreset(_ preset: FKActionSheetAppearancePreset) -> Self {
    var copy = self
    copy.configuration.appearance = .preset(preset)
    return copy
  }

  /// Sets presentation tuning.
  public func presentation(_ presentation: FKActionSheetPresentationConfiguration) -> Self {
    var copy = self
    copy.configuration.presentation = presentation
    return copy
  }

  /// Sets the presentation placement style.
  public func presentationStyle(_ style: FKActionSheetPresentationStyle) -> Self {
    var copy = self
    copy.configuration.presentation.style = style
    return copy
  }

  /// Sets whether non-cancel actions dismiss the sheet automatically.
  public func dismissesAfterActionSelection(_ enabled: Bool) -> Self {
    var copy = self
    copy.configuration.dismissesAfterActionSelection = enabled
    return copy
  }

  /// Sets handler timing relative to dismissal.
  public func handlerTiming(_ timing: FKActionSheetHandlerTiming) -> Self {
    var copy = self
    copy.configuration.handlerTiming = timing
    return copy
  }

  /// Sets single-selection behavior.
  public func selection(_ selection: FKActionSheetSelectionConfiguration) -> Self {
    var copy = self
    copy.configuration.selection = selection
    return copy
  }

  /// Caps scrollable content height before the list scrolls inside the sheet.
  public func maximumPanelHeight(_ height: CGFloat?) -> Self {
    var copy = self
    copy.configuration.presentation.maximumPanelHeight = height
    return copy
  }

  /// Sets haptics configuration.
  public func haptics(_ haptics: FKActionSheetHapticsConfiguration) -> Self {
    var copy = self
    copy.configuration.haptics = haptics
    return copy
  }

  /// Sets lifecycle hooks.
  public func hooks(_ hooks: FKActionSheetLifecycleHooks) -> Self {
    var copy = self
    copy.configuration.hooks = hooks
    return copy
  }

  /// Sets a delegate.
  public func delegate(_ delegate: FKActionSheetDelegate?) -> Self {
    var copy = self
    copy.configuration.delegate = delegate
    return copy
  }

  /// Builds the configuration value.
  public func build() -> FKActionSheetConfiguration {
    configuration
  }

  /// Presents using the accumulated configuration.
  @discardableResult
  public func present(
    from presenter: UIViewController,
    animated: Bool = true,
    completion: (() -> Void)? = nil
  ) throws -> FKActionSheetHandle {
    try FKActionSheet.present(configuration: build(), from: presenter, animated: animated, completion: completion)
  }

  /// Presents using a host context (window, scene, or presenter).
  @discardableResult
  public func present(
    hostContext: FKActionSheetPresentationHostContext,
    animated: Bool = true,
    completion: (() -> Void)? = nil
  ) throws -> FKActionSheetHandle {
    try FKActionSheet.present(configuration: build(), hostContext: hostContext, animated: animated, completion: completion)
  }

  /// Presents at most one sheet per `id` until it is dismissed.
  @discardableResult
  public func presentOnce(
    id: String,
    from presenter: UIViewController,
    animated: Bool = true,
    completion: (() -> Void)? = nil
  ) throws -> FKActionSheetHandle? {
    try FKActionSheet.presentOnce(
      id: id,
      configuration: build(),
      from: presenter,
      animated: animated,
      completion: completion
    )
  }

  /// Presents at most one sheet per `id` until it is dismissed.
  @discardableResult
  public func presentOnce(
    id: String,
    hostContext: FKActionSheetPresentationHostContext = .init(),
    animated: Bool = true,
    completion: (() -> Void)? = nil
  ) throws -> FKActionSheetHandle? {
    try FKActionSheet.presentOnce(
      id: id,
      configuration: build(),
      hostContext: hostContext,
      animated: animated,
      completion: completion
    )
  }
}
