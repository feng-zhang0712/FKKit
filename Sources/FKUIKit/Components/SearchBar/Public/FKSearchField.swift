import UIKit

/// Compact search control for inline filters — search icon, field, clear, and debounced callbacks without a cancel column.
@MainActor
public final class FKSearchField: FKSearchControlBase {
  /// Baseline copied by parameterless initializers until you replace ``configuration``.
  public static var defaultConfiguration: FKSearchFieldConfiguration {
    get { FKSearchFieldDefaults.defaultConfiguration }
    set { FKSearchFieldDefaults.defaultConfiguration = newValue }
  }

  /// Style, debounce, and accessory behavior.
  public var configuration: FKSearchFieldConfiguration {
    get {
      FKSearchFieldConfiguration(
        layout: runtimeConfiguration.layout,
        appearance: runtimeConfiguration.appearance,
        textInput: runtimeConfiguration.textInput,
        debounce: runtimeConfiguration.debounce,
        clearButton: runtimeConfiguration.clearButton,
        loading: runtimeConfiguration.loading,
        submit: runtimeConfiguration.submit,
        accessibility: runtimeConfiguration.accessibility
      )
    }
    set {
      runtimeConfiguration = FKSearchRuntimeConfiguration(fieldConfiguration: newValue)
    }
  }

  public init(frame: CGRect) {
    super.init(runtimeConfiguration: FKSearchRuntimeConfiguration(fieldConfiguration: FKSearchFieldDefaults.defaultConfiguration))
  }

  /// Creates a compact search field with explicit configuration and placeholder.
  public init(configuration: FKSearchFieldConfiguration = FKSearchFieldDefaults.defaultConfiguration, placeholder: String? = nil) {
    super.init(runtimeConfiguration: FKSearchRuntimeConfiguration(fieldConfiguration: configuration))
    self.placeholder = placeholder
  }

  /// Replaces configuration wholesale.
  public func apply(_ configuration: FKSearchFieldConfiguration) {
    self.configuration = configuration
  }

  /// Mutates configuration in place.
  public func apply(_ block: (inout FKSearchFieldConfiguration) -> Void) {
    var copy = configuration
    block(&copy)
    configuration = copy
  }

  public override func setText(_ text: String, options: FKSearchTextUpdateOptions = .silent) {
    super.setText(text, options: options)
  }

  public override func setLoading(_ isLoading: Bool, animated: Bool = true) {
    super.setLoading(isLoading, animated: animated)
  }
}
