import Foundation

/// Configuration for ``FKFormCellVoiceInputCell`` (X-59).
public struct FKFormCellVoiceInputConfiguration: Sendable, Equatable {
  public var label: String?
  public var placeholder: String?
  public var text: String
  public var isEnabled: Bool

  /// Creates a voice input field configuration.
  public init(
    label: String? = nil,
    placeholder: String? = "Speak or type…",
    text: String = "",
    isEnabled: Bool = true
  ) {
    self.label = label
    self.placeholder = placeholder
    self.text = text
    self.isEnabled = isEnabled
  }
}
