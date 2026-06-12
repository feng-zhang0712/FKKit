import Foundation

/// ListKit-friendly row model for ``FKFormCellMediaGridCell``.
public struct FKFormCellMediaGridRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKFormCellMediaGridConfiguration
  public var images: [FKCellImageContent]

  public init(
    id: String,
    configuration: FKFormCellMediaGridConfiguration,
    images: [FKCellImageContent] = []
  ) {
    self.id = id
    self.configuration = configuration
    self.images = images
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

extension FKFormCellMediaGridRow {
  public static func == (lhs: FKFormCellMediaGridRow, rhs: FKFormCellMediaGridRow) -> Bool {
    lhs.id == rhs.id && lhs.configuration == rhs.configuration && lhs.images == rhs.images
  }
}
