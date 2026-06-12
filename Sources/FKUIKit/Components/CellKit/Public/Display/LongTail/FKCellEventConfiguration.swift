import UIKit

/// Configuration for ``FKCellEventCell`` (D-51).
public struct FKCellEventConfiguration: Sendable, Equatable {
  public var monthText: String
  public var dayText: String
  public var title: String
  public var subtitle: String?
  public var accentColor: UIColor
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  public init(
    monthText: String,
    dayText: String,
    title: String,
    subtitle: String? = nil,
    accentColor: UIColor = .systemBlue,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.monthText = monthText
    self.dayText = dayText
    self.title = title
    self.subtitle = subtitle
    self.accentColor = accentColor
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}

extension FKCellEventConfiguration {
  public static func == (lhs: FKCellEventConfiguration, rhs: FKCellEventConfiguration) -> Bool {
    lhs.monthText == rhs.monthText && lhs.dayText == rhs.dayText && lhs.title == rhs.title &&
      lhs.subtitle == rhs.subtitle && lhs.accentColor == rhs.accentColor &&
      lhs.isEnabled == rhs.isEnabled && lhs.separatorPolicy == rhs.separatorPolicy &&
      lhs.isLastInSection == rhs.isLastInSection
  }
}
