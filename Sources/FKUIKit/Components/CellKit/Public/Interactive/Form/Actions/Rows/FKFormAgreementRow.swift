import Foundation

/// ListKit-friendly row model for ``FKFormCellAgreementCell`` (F-05).
public struct FKFormAgreementRow: Sendable, Equatable, Hashable {
  public var id: String
  public var isChecked: Bool
  public var configuration: FKFormCellAgreementConfiguration

  /// Creates an agreement row model.
  public init(
    id: String,
    isChecked: Bool = false,
    configuration: FKFormCellAgreementConfiguration
  ) {
    self.id = id
    self.isChecked = isChecked
    self.configuration = configuration
  }

  /// Convenience builder for F-05.
  public init(
    id: String,
    text: String,
    linkRanges: [FKCellLinkRange] = [],
    isChecked: Bool = false,
    isEnabled: Bool = true
  ) {
    self.id = id
    self.isChecked = isChecked
    self.configuration = FKFormCellAgreementConfiguration(
      text: text,
      linkRanges: linkRanges,
      isChecked: isChecked,
      isEnabled: isEnabled
    )
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
