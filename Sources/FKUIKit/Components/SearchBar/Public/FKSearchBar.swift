import UIKit

/// Full-featured search control with leading icon, debounced query callbacks, clear, optional cancel, and loading state.
///
/// Assign ``configuration`` to change layout and appearance. Use ``callbacks`` for event handling; optional ``delegate`` mirrors events when callbacks are unset.
@MainActor
public final class FKSearchBar: FKSearchControlBase {
  /// Baseline copied by parameterless initializers until you replace ``configuration``.
  public static var defaultConfiguration: FKSearchBarConfiguration {
    get { FKSearchBarDefaults.defaultConfiguration }
    set { FKSearchBarDefaults.defaultConfiguration = newValue }
  }

  /// Style, debounce, and accessory behavior.
  public var configuration: FKSearchBarConfiguration {
    get {
      FKSearchBarConfiguration(
        layout: runtimeConfiguration.layout,
        appearance: runtimeConfiguration.appearance,
        textInput: runtimeConfiguration.textInput,
        debounce: runtimeConfiguration.debounce,
        clearButton: runtimeConfiguration.clearButton,
        cancelButton: runtimeConfiguration.cancelButton ?? FKSearchCancelButtonConfiguration(visibility: .never),
        loading: runtimeConfiguration.loading,
        submit: runtimeConfiguration.submit,
        accessibility: runtimeConfiguration.accessibility
      )
    }
    set {
      runtimeConfiguration = FKSearchRuntimeConfiguration(barConfiguration: newValue)
    }
  }

  /// Optional delegate; methods fire only when the matching ``callbacks`` handler is `nil`.
  public weak var delegate: FKSearchBarDelegate?

  public init(frame: CGRect) {
    super.init(runtimeConfiguration: FKSearchRuntimeConfiguration(barConfiguration: FKSearchBarDefaults.defaultConfiguration))
  }

  /// Creates a search bar with explicit configuration and placeholder.
  public init(configuration: FKSearchBarConfiguration = FKSearchBarDefaults.defaultConfiguration, placeholder: String? = nil) {
    super.init(runtimeConfiguration: FKSearchRuntimeConfiguration(barConfiguration: configuration))
    self.placeholder = placeholder
  }

  /// Replaces configuration wholesale.
  public func apply(_ configuration: FKSearchBarConfiguration) {
    self.configuration = configuration
  }

  /// Mutates configuration in place.
  public func apply(_ block: (inout FKSearchBarConfiguration) -> Void) {
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

  // MARK: - Event forwarding

  public override func emitTextChanged(_ text: String) {
    if let handler = callbacks.onTextChanged {
      handler(text)
    } else {
      delegate?.searchBar(self, textDidChange: text)
    }
  }

  public override func emitSearchQueryChanged(_ query: String) {
    if let handler = callbacks.onSearchQueryChanged {
      handler(query)
    } else {
      delegate?.searchBar(self, searchQueryDidChange: query)
    }
  }

  public override func emitSubmit(_ query: String) {
    if let handler = callbacks.onSubmit {
      handler(query)
    } else {
      delegate?.searchBarSearchButtonClicked(self)
    }
  }

  public override func emitClear() {
    if callbacks.onClear != nil {
      callbacks.onClear?()
    } else {
      delegate?.searchBarClearButtonClicked(self)
    }
  }

  public override func emitCancel() {
    if callbacks.onCancel != nil {
      callbacks.onCancel?()
    } else {
      delegate?.searchBarCancelButtonClicked(self)
    }
  }

  public override func emitEditingDidBegin() {
    if callbacks.onEditingDidBegin != nil {
      callbacks.onEditingDidBegin?()
    } else {
      delegate?.searchBarTextDidBeginEditing(self)
    }
  }

  public override func emitEditingDidEnd() {
    if callbacks.onEditingDidEnd != nil {
      callbacks.onEditingDidEnd?()
    } else {
      delegate?.searchBarTextDidEndEditing(self)
    }
  }
}
