import Foundation

/// Pure data configuration for ``FKCellDisclosureCell`` (D-01).
public struct FKCellDisclosureConfiguration: Sendable, Equatable {
  public var title: String
  public var isEnabled: Bool
  public var showsDisclosure: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a disclosure row configuration.
  public init(
    title: String,
    isEnabled: Bool = true,
    showsDisclosure: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.title = title
    self.isEnabled = isEnabled
    self.showsDisclosure = showsDisclosure
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
