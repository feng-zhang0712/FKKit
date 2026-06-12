import Foundation

/// Configuration for ``FKFormCellSettingsLinkCell`` (X-71).
public struct FKFormCellSettingsLinkConfiguration: Sendable, Equatable {
  public var body: String
  public var linkTitle: String
  public var isEnabled: Bool

  /// Creates a settings deep-link row configuration.
  public init(
    body: String,
    linkTitle: String = "Open Settings",
    isEnabled: Bool = true
  ) {
    self.body = body
    self.linkTitle = linkTitle
    self.isEnabled = isEnabled
  }
}
