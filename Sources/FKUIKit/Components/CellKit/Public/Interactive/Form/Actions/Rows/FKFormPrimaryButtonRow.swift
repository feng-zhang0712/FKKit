import Foundation

/// ListKit-friendly row model for ``FKFormCellPrimaryButtonCell`` (F-09).
public struct FKFormPrimaryButtonRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKFormCellPrimaryButtonConfiguration

  /// Creates a primary button row model.
  public init(id: String, configuration: FKFormCellPrimaryButtonConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  /// Convenience builder for F-09.
  public init(id: String, title: String, isEnabled: Bool = true, isLoading: Bool = false) {
    self.id = id
    self.configuration = FKFormCellPrimaryButtonConfiguration(
      title: title,
      isEnabled: isEnabled,
      isLoading: isLoading
    )
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
