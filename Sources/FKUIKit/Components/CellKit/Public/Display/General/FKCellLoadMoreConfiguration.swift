import Foundation

/// Configuration for ``FKCellLoadMoreCell`` (D-79).
public struct FKCellLoadMoreConfiguration: Sendable, Equatable {
  public var title: String
  public var isLoading: Bool
  public var isEnabled: Bool

  public init(
    title: String = "Load more",
    isLoading: Bool = false,
    isEnabled: Bool = true
  ) {
    self.title = title
    self.isLoading = isLoading
    self.isEnabled = isEnabled
  }
}
