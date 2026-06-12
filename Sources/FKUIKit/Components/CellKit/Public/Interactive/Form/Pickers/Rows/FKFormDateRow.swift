import Foundation

/// ListKit-friendly row model for ``FKFormCellDateCell`` (F-08).
public struct FKFormDateRow: Sendable, Equatable, Hashable {
  public var id: String
  public var date: Date
  public var configuration: FKFormCellDateConfiguration

  /// Creates a date row model.
  public init(
    id: String,
    date: Date = Date(),
    configuration: FKFormCellDateConfiguration
  ) {
    self.id = id
    self.date = date
    self.configuration = configuration
  }

  /// Convenience builder for F-08.
  public init(
    id: String,
    date: Date = Date(),
    layout: FKFormCellLayout = .cardStacked,
    label: String?,
    isRequired: Bool = false
  ) {
    self.id = id
    self.date = date
    self.configuration = .date(layout: layout, label: label, isRequired: isRequired)
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
