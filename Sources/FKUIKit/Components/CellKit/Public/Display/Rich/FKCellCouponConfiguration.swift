import UIKit

/// Configuration for ``FKCellCouponCell`` (D-31).
public struct FKCellCouponConfiguration: @unchecked Sendable, Equatable {
  public var accentColor: UIColor
  public var amountText: String
  public var title: String
  public var rulesText: String
  public var actionTitle: String?
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a coupon row configuration.
  public init(
    accentColor: UIColor = .systemOrange,
    amountText: String,
    title: String,
    rulesText: String,
    actionTitle: String? = nil,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.accentColor = accentColor
    self.amountText = amountText
    self.title = title
    self.rulesText = rulesText
    self.actionTitle = actionTitle
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}

extension FKCellCouponConfiguration {
  public static func == (lhs: FKCellCouponConfiguration, rhs: FKCellCouponConfiguration) -> Bool {
    lhs.accentColor == rhs.accentColor
      && lhs.amountText == rhs.amountText
      && lhs.title == rhs.title
      && lhs.rulesText == rhs.rulesText
      && lhs.actionTitle == rhs.actionTitle
      && lhs.separatorPolicy == rhs.separatorPolicy
      && lhs.isLastInSection == rhs.isLastInSection
  }
}
