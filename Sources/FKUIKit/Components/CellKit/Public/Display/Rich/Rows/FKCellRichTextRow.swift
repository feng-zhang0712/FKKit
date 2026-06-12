import Foundation

/// ListKit-friendly row model for ``FKCellRichTextCell``.
public struct FKCellRichTextRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellRichTextConfiguration

  /// Creates a rich text row model.
  public init(id: String, configuration: FKCellRichTextConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
