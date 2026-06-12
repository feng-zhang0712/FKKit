import Foundation

/// ListKit-friendly row model for ``FKFormCellTimeCell`` (F-08).
public struct FKFormTimeRow: Sendable, Equatable, Hashable {
  public var id: String
  public var time: Date
  public var configuration: FKFormCellTimeConfiguration

  /// Creates a time row model.
  public init(
    id: String,
    time: Date = Date(),
    configuration: FKFormCellTimeConfiguration
  ) {
    self.id = id
    self.time = time
    self.configuration = configuration
  }

  /// Convenience builder for F-08.
  public init(
    id: String,
    time: Date = Date(),
    layout: FKFormCellLayout = .cardStacked,
    label: String?,
    isRequired: Bool = false
  ) {
    self.id = id
    self.time = time
    self.configuration = .time(layout: layout, label: label, isRequired: isRequired)
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
