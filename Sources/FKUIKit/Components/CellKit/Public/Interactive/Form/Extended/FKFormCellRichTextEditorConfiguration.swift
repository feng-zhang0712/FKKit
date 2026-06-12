import Foundation

/// Configuration for ``FKFormCellRichTextEditorCell`` (X-58).
public struct FKFormCellRichTextEditorConfiguration: Sendable, Equatable {
  public var label: String?
  public var placeholder: String?
  public var text: String
  public var maxLength: Int?
  public var isEnabled: Bool

  /// Creates a rich text editor row configuration.
  public init(
    label: String? = nil,
    placeholder: String? = nil,
    text: String = "",
    maxLength: Int? = 5000,
    isEnabled: Bool = true
  ) {
    self.label = label
    self.placeholder = placeholder
    self.text = text
    self.maxLength = maxLength
    self.isEnabled = isEnabled
  }
}
