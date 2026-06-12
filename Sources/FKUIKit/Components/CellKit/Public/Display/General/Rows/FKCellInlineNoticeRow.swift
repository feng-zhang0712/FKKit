import Foundation

/// ListKit-friendly row model for ``FKCellInlineNoticeCell`` (D-56).
public struct FKCellInlineNoticeRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellInlineNoticeConfiguration

  public init(id: String, configuration: FKCellInlineNoticeConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
