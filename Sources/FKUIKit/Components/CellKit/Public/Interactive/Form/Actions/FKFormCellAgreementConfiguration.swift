import Foundation

/// Configuration for ``FKFormCellAgreementCell`` (X-52, F-05).
public struct FKFormCellAgreementConfiguration: Sendable, Equatable {
  public var text: String
  public var linkRanges: [FKCellLinkRange]
  public var isChecked: Bool
  public var isEnabled: Bool

  /// Creates an agreement checkbox row configuration.
  public init(
    text: String,
    linkRanges: [FKCellLinkRange] = [],
    isChecked: Bool = false,
    isEnabled: Bool = true
  ) {
    self.text = text
    self.linkRanges = linkRanges
    self.isChecked = isChecked
    self.isEnabled = isEnabled
  }
}
