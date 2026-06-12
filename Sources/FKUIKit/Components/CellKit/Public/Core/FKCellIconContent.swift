import UIKit

/// Leading icon payload for settings-style CellKit rows.
public struct FKCellIconContent: @unchecked Sendable, Equatable {
  public var configuration: FKIconViewConfiguration
  public var symbolName: String?
  public var image: UIImage?

  /// Creates icon content for ``FKIconView``-backed leading slots.
  public init(
    configuration: FKIconViewConfiguration = FKIconViewConfiguration(),
    symbolName: String? = nil,
    image: UIImage? = nil
  ) {
    self.configuration = configuration
    self.symbolName = symbolName
    self.image = image
  }
}

extension FKCellIconContent {
  public static func == (lhs: FKCellIconContent, rhs: FKCellIconContent) -> Bool {
    lhs.configuration == rhs.configuration
      && lhs.symbolName == rhs.symbolName
      && lhs.image === rhs.image
  }
}
