import Foundation

/// Closure-based event handlers for search controls.
///
/// Callbacks take precedence over delegate methods when both are set for the same event.
public struct FKSearchCallbacks {
  /// Fired on every keystroke (raw text, not debounced).
  public var onTextChanged: (@MainActor (String) -> Void)?
  /// Fired after the debounce interval when debouncing is enabled.
  public var onSearchQueryChanged: (@MainActor (String) -> Void)?
  /// Fired when the user taps the Return key (`.search`).
  public var onSubmit: (@MainActor (String) -> Void)?
  /// Fired when the clear control is tapped.
  public var onClear: (@MainActor () -> Void)?
  /// Fired when the cancel control is tapped (`FKSearchBar` only).
  public var onCancel: (@MainActor () -> Void)?
  /// Fired when the text field becomes first responder.
  public var onEditingDidBegin: (@MainActor () -> Void)?
  /// Fired when the text field resigns first responder.
  public var onEditingDidEnd: (@MainActor () -> Void)?

  public init(
    onTextChanged: (@MainActor (String) -> Void)? = nil,
    onSearchQueryChanged: (@MainActor (String) -> Void)? = nil,
    onSubmit: (@MainActor (String) -> Void)? = nil,
    onClear: (@MainActor () -> Void)? = nil,
    onCancel: (@MainActor () -> Void)? = nil,
    onEditingDidBegin: (@MainActor () -> Void)? = nil,
    onEditingDidEnd: (@MainActor () -> Void)? = nil
  ) {
    self.onTextChanged = onTextChanged
    self.onSearchQueryChanged = onSearchQueryChanged
    self.onSubmit = onSubmit
    self.onClear = onClear
    self.onCancel = onCancel
    self.onEditingDidBegin = onEditingDidBegin
    self.onEditingDidEnd = onEditingDidEnd
  }
}
