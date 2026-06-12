import Foundation

/// Configuration for ``FKCellPaymentMethodCell`` (D-30).
public struct FKCellPaymentMethodConfiguration: Sendable, Equatable {
  public var brandIcon: FKCellIconContent
  public var maskedNumber: String
  public var expiry: String?
  public var badge: FKStatusPillConfiguration?
  public var showsDisclosure: Bool
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  public init(
    brandIcon: FKCellIconContent = FKCellIconContent(symbolName: "creditcard.fill"),
    maskedNumber: String,
    expiry: String? = nil,
    badge: FKStatusPillConfiguration? = nil,
    showsDisclosure: Bool = true,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.brandIcon = brandIcon
    self.maskedNumber = maskedNumber
    self.expiry = expiry
    self.badge = badge
    self.showsDisclosure = showsDisclosure
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
