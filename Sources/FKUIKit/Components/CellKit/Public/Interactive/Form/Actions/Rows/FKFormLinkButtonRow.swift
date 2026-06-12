import Foundation

/// ListKit-friendly row model for ``FKFormCellLinkButtonCell`` (F-10).
public struct FKFormLinkButtonRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKFormCellLinkButtonConfiguration

  /// Creates a link button row model.
  public init(id: String, configuration: FKFormCellLinkButtonConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  /// Convenience builder for F-10.
  public init(id: String, title: String, isEnabled: Bool = true) {
    self.id = id
    self.configuration = .linkButton(title: title, isEnabled: isEnabled)
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
