import Foundation

/// ListKit-friendly row model for ``FKCellArticleCell`` (D-25).
public struct FKCellArticleRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellArticleConfiguration

  public init(id: String, configuration: FKCellArticleConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
