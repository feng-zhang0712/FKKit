import Foundation

/// Configuration for ``FKFormCellPrimaryButtonCell`` (X-49, F-09).
public struct FKFormCellPrimaryButtonConfiguration: Sendable, Equatable {
  public var title: String
  public var isEnabled: Bool
  public var isLoading: Bool

  /// Creates a primary submit button configuration.
  public init(
    title: String,
    isEnabled: Bool = true,
    isLoading: Bool = false
  ) {
    self.title = title
    self.isEnabled = isEnabled
    self.isLoading = isLoading
  }
}
