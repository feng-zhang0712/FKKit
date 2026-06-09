import UIKit

/// Full configuration for ``FKSearchBar``.
public struct FKSearchBarConfiguration: Sendable, Equatable {
  public var layout: FKSearchLayoutConfiguration
  public var appearance: FKSearchAppearanceConfiguration
  public var textInput: FKSearchTextInputTraitsConfiguration
  public var debounce: FKSearchDebounceConfiguration
  public var clearButton: FKSearchClearButtonConfiguration
  public var cancelButton: FKSearchCancelButtonConfiguration
  public var loading: FKSearchLoadingConfiguration
  public var submit: FKSearchSubmitConfiguration
  public var accessibility: FKSearchAccessibilityConfiguration

  public init(
    layout: FKSearchLayoutConfiguration = FKSearchLayoutConfiguration(),
    appearance: FKSearchAppearanceConfiguration = FKSearchAppearanceConfiguration(),
    textInput: FKSearchTextInputTraitsConfiguration = FKSearchTextInputTraitsConfiguration(),
    debounce: FKSearchDebounceConfiguration = FKSearchDebounceConfiguration(),
    clearButton: FKSearchClearButtonConfiguration = FKSearchClearButtonConfiguration(),
    cancelButton: FKSearchCancelButtonConfiguration = FKSearchCancelButtonConfiguration(),
    loading: FKSearchLoadingConfiguration = FKSearchLoadingConfiguration(),
    submit: FKSearchSubmitConfiguration = FKSearchSubmitConfiguration(),
    accessibility: FKSearchAccessibilityConfiguration = FKSearchAccessibilityConfiguration()
  ) {
    self.layout = layout
    self.appearance = appearance
    self.textInput = textInput
    self.debounce = debounce
    self.clearButton = clearButton
    self.cancelButton = cancelButton
    self.loading = loading
    self.submit = submit
    self.accessibility = accessibility
  }
}

/// Global defaults for ``FKSearchBar`` (mutate at launch to customize app-wide search styling).
public enum FKSearchBarDefaults {
  /// Baseline configuration for new ``FKSearchBar`` instances.
  public nonisolated(unsafe) static var defaultConfiguration = FKSearchBarConfiguration()

  /// Preset tuned for `navigationItem.titleView` with cancel-on-focus behavior.
  public static func navigationBar() -> FKSearchBarConfiguration {
    var config = FKSearchBarConfiguration()
    config.layout.style = .navigationBar
    config.layout.showsUnderline = false
    config.appearance.backgroundMaterial = .none
    config.appearance.cornerStyle = .fixed(10)
    config.cancelButton.visibility = .whileEditing
    config.cancelButton.policy = .clearAndResign
    return config
  }

  /// Preset for a full-width rounded card below navigation.
  public static func inlineCard() -> FKSearchBarConfiguration {
    var config = FKSearchBarConfiguration()
    config.layout.style = .inlineCard
    config.appearance.backgroundColor = .secondarySystemBackground
    config.appearance.cornerStyle = .capsule
    config.cancelButton.visibility = .never
    return config
  }
}
