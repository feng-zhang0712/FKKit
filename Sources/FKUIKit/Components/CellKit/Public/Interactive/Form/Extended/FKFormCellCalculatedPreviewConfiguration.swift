import Foundation

/// Configuration for ``FKFormCellCalculatedPreviewCell`` (X-68).
public struct FKFormCellCalculatedPreviewConfiguration: Sendable, Equatable {
  public var label: String?
  public var placeholder: String?
  public var text: String
  public var previewText: String
  public var isEnabled: Bool

  /// Creates a field with a live calculated preview line.
  public init(
    label: String? = nil,
    placeholder: String? = nil,
    text: String = "",
    previewText: String = "",
    isEnabled: Bool = true
  ) {
    self.label = label
    self.placeholder = placeholder
    self.text = text
    self.previewText = previewText
    self.isEnabled = isEnabled
  }
}
