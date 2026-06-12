import Foundation

/// ListKit-friendly row model for ``FKFormCellInlineExpandCell``.
public struct FKFormCellInlineExpandRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKFormCellInlineExpandConfiguration
  public var isExpanded: Bool
  public var fieldText: String

  public init(
    id: String,
    configuration: FKFormCellInlineExpandConfiguration,
    isExpanded: Bool = false,
    fieldText: String = ""
  ) {
    self.id = id
    self.configuration = configuration
    self.isExpanded = isExpanded
    self.fieldText = fieldText
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
