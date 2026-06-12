import Foundation

/// Configuration for ``FKCellValueDisclosureCell`` (D-03, I-04, I-07).
public struct FKCellValueDisclosureConfiguration: Sendable, Equatable {
  public var title: String
  public var value: String
  public var valueNumberOfLines: Int
  public var showsDisclosure: Bool
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a value + chevron navigation row configuration.
  public init(
    title: String,
    value: String,
    valueNumberOfLines: Int = 1,
    showsDisclosure: Bool = true,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.title = title
    self.value = value
    self.valueNumberOfLines = valueNumberOfLines
    self.showsDisclosure = showsDisclosure
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
