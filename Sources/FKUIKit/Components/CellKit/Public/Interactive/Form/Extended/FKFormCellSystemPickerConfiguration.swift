import Foundation

/// Configuration for ``FKFormCellSystemPickerCell`` (X-70).
public struct FKFormCellSystemPickerConfiguration: Sendable, Equatable {
  public var label: String?
  public var summary: String
  public var chooseButtonTitle: String
  public var isEnabled: Bool

  /// Creates a system picker summary row configuration.
  public init(
    label: String? = nil,
    summary: String = "Nothing selected",
    chooseButtonTitle: String = "Choose…",
    isEnabled: Bool = true
  ) {
    self.label = label
    self.summary = summary
    self.chooseButtonTitle = chooseButtonTitle
    self.isEnabled = isEnabled
  }
}
