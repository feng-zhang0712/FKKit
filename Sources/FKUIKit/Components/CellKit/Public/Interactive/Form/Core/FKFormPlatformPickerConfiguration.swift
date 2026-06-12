import Foundation

/// Display payload for the platform leading zone in social account form rows (X-07).
public struct FKFormPlatformPickerConfiguration: Sendable, Equatable {
  public var platformName: String
  public var icon: FKCellIconContent?

  /// Creates a platform picker configuration.
  public init(platformName: String, icon: FKCellIconContent? = nil) {
    self.platformName = platformName
    self.icon = icon
  }
}
