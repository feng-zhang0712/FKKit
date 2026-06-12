import Foundation

/// Configuration for ``FKFormCellLinkButtonCell`` (X-51, F-10).
public struct FKFormCellLinkButtonConfiguration: Sendable, Equatable {
  public var title: String
  public var isEnabled: Bool

  /// Creates a link-style button row configuration.
  public init(title: String, isEnabled: Bool = true) {
    self.title = title
    self.isEnabled = isEnabled
  }
}

// MARK: - Semantic preset (F-10)

public extension FKFormCellLinkButtonConfiguration {
  /// Link button preset (F-10).
  static func linkButton(title: String, isEnabled: Bool = true) -> FKFormCellLinkButtonConfiguration {
    FKFormCellLinkButtonConfiguration(title: title, isEnabled: isEnabled)
  }
}
