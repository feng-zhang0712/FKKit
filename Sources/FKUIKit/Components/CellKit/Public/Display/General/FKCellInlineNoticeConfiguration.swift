import UIKit

/// Configuration for ``FKCellInlineNoticeCell`` (D-56).
public struct FKCellInlineNoticeConfiguration: @unchecked Sendable, Equatable {
  public var message: String
  public var backgroundColor: UIColor
  public var textColor: UIColor
  public var showsCloseButton: Bool
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  public init(
    message: String,
    backgroundColor: UIColor = .systemYellow.withAlphaComponent(0.2),
    textColor: UIColor = .label,
    showsCloseButton: Bool = true,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.message = message
    self.backgroundColor = backgroundColor
    self.textColor = textColor
    self.showsCloseButton = showsCloseButton
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}

extension FKCellInlineNoticeConfiguration {
  public static func == (lhs: FKCellInlineNoticeConfiguration, rhs: FKCellInlineNoticeConfiguration) -> Bool {
    lhs.message == rhs.message
      && lhs.backgroundColor == rhs.backgroundColor
      && lhs.textColor == rhs.textColor
      && lhs.showsCloseButton == rhs.showsCloseButton
      && lhs.isEnabled == rhs.isEnabled
      && lhs.separatorPolicy == rhs.separatorPolicy
      && lhs.isLastInSection == rhs.isLastInSection
  }
}
