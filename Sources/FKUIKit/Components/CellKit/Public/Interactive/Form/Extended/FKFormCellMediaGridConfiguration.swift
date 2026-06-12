import Foundation

/// Configuration for ``FKFormCellMediaGridCell`` (X-63).
public struct FKFormCellMediaGridConfiguration: Sendable, Equatable {
  public var label: String?
  public var images: [FKCellImageContent]
  public var maxCount: Int
  public var isEnabled: Bool

  /// Creates a multi-image upload grid configuration.
  public init(
    label: String? = "Photos",
    images: [FKCellImageContent] = [],
    maxCount: Int = 9,
    isEnabled: Bool = true
  ) {
    self.label = label
    self.images = images
    self.maxCount = max(1, maxCount)
    self.isEnabled = isEnabled
  }
}

extension FKFormCellMediaGridConfiguration {
  public static func == (lhs: FKFormCellMediaGridConfiguration, rhs: FKFormCellMediaGridConfiguration) -> Bool {
    lhs.label == rhs.label && lhs.images == rhs.images && lhs.maxCount == rhs.maxCount && lhs.isEnabled == rhs.isEnabled
  }
}
