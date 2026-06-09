import UIKit

/// Compact search configuration without a cancel column — for inline filters and toolbars.
public struct FKSearchFieldConfiguration: Sendable, Equatable {
  public var layout: FKSearchLayoutConfiguration
  public var appearance: FKSearchAppearanceConfiguration
  public var textInput: FKSearchTextInputTraitsConfiguration
  public var debounce: FKSearchDebounceConfiguration
  public var clearButton: FKSearchClearButtonConfiguration
  public var loading: FKSearchLoadingConfiguration
  public var submit: FKSearchSubmitConfiguration
  public var accessibility: FKSearchAccessibilityConfiguration

  public init(
    layout: FKSearchLayoutConfiguration = FKSearchLayoutConfiguration(),
    appearance: FKSearchAppearanceConfiguration = FKSearchAppearanceConfiguration(),
    textInput: FKSearchTextInputTraitsConfiguration = FKSearchTextInputTraitsConfiguration(),
    debounce: FKSearchDebounceConfiguration = FKSearchDebounceConfiguration(),
    clearButton: FKSearchClearButtonConfiguration = FKSearchClearButtonConfiguration(),
    loading: FKSearchLoadingConfiguration = FKSearchLoadingConfiguration(),
    submit: FKSearchSubmitConfiguration = FKSearchSubmitConfiguration(),
    accessibility: FKSearchAccessibilityConfiguration = FKSearchAccessibilityConfiguration()
  ) {
    self.layout = layout
    self.appearance = appearance
    self.textInput = textInput
    self.debounce = debounce
    self.clearButton = clearButton
    self.loading = loading
    self.submit = submit
    self.accessibility = accessibility
  }
}

/// Global defaults for ``FKSearchField``.
public enum FKSearchFieldDefaults {
  /// Baseline configuration for new ``FKSearchField`` instances.
  public nonisolated(unsafe) static var defaultConfiguration = FKSearchFieldConfiguration()

  /// Preset for compact embedded filters in content areas.
  public static func compactFilter() -> FKSearchFieldConfiguration {
    var config = FKSearchFieldConfiguration()
    config.layout.style = .inlineCard
    config.layout.minimumHeight = 40
    config.appearance.cornerStyle = .capsule
    return config
  }
}
