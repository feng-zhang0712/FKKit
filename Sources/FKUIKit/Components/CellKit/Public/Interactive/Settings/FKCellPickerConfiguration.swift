import Foundation

/// Configuration for ``FKCellPickerCell`` (I-05).
public struct FKCellPickerConfiguration: Sendable, Equatable {
  public var title: String
  public var icon: FKCellIconContent?
  public var value: String
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a settings picker row configuration.
  public init(
    title: String,
    icon: FKCellIconContent? = nil,
    value: String,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.title = title
    self.icon = icon
    self.value = value
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
