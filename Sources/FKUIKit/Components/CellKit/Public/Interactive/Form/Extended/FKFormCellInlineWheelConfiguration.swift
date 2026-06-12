import Foundation

/// Configuration for ``FKFormCellInlineWheelCell`` (X-67).
public struct FKFormCellInlineWheelConfiguration: Sendable, Equatable {
  public var label: String?
  public var options: [String]
  public var selectedIndex: Int
  public var isExpanded: Bool
  public var isEnabled: Bool

  /// Creates an inline wheel picker configuration.
  public init(
    label: String? = nil,
    options: [String] = [],
    selectedIndex: Int = 0,
    isExpanded: Bool = true,
    isEnabled: Bool = true
  ) {
    self.label = label
    self.options = options
    self.selectedIndex = selectedIndex
    self.isExpanded = isExpanded
    self.isEnabled = isEnabled
  }
}
