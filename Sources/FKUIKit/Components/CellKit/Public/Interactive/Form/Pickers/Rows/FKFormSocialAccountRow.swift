import Foundation

/// ListKit-friendly row model for ``FKFormCellSocialAccountCell``.
public struct FKFormSocialAccountRow: Sendable, Equatable, Hashable {
  public var id: String
  public var username: String
  public var configuration: FKFormCellSocialAccountConfiguration

  /// Creates a social account row model.
  public init(
    id: String,
    username: String = "",
    configuration: FKFormCellSocialAccountConfiguration
  ) {
    self.id = id
    self.username = username
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
