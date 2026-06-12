import Foundation

/// Configuration for ``FKCellAddressCell`` (D-43).
public struct FKCellAddressConfiguration: Sendable, Equatable {
  public var addressLines: [String]
  public var contactLine: String?
  public var badge: FKStatusPillConfiguration?
  public var showsDisclosure: Bool
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  public init(
    addressLines: [String],
    contactLine: String? = nil,
    badge: FKStatusPillConfiguration? = nil,
    showsDisclosure: Bool = true,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.addressLines = addressLines
    self.contactLine = contactLine
    self.badge = badge
    self.showsDisclosure = showsDisclosure
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
