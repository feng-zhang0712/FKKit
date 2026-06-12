import Foundation

/// Configuration for ``FKFormCellMapRadiusCell`` (X-72).
public struct FKFormCellMapRadiusConfiguration: Sendable, Equatable {
  public var label: String?
  public var mapImage: FKCellImageContent?
  public var radiusMeters: Double
  public var minimumRadius: Double
  public var maximumRadius: Double
  public var isEnabled: Bool

  /// Creates a map snapshot with radius slider configuration.
  public init(
    label: String? = "Delivery radius",
    mapImage: FKCellImageContent? = nil,
    radiusMeters: Double = 1000,
    minimumRadius: Double = 500,
    maximumRadius: Double = 5000,
    isEnabled: Bool = true
  ) {
    self.label = label
    self.mapImage = mapImage
    self.radiusMeters = radiusMeters
    self.minimumRadius = minimumRadius
    self.maximumRadius = maximumRadius
    self.isEnabled = isEnabled
  }
}

extension FKFormCellMapRadiusConfiguration {
  public static func == (lhs: FKFormCellMapRadiusConfiguration, rhs: FKFormCellMapRadiusConfiguration) -> Bool {
    lhs.label == rhs.label
      && lhs.mapImage == rhs.mapImage
      && lhs.radiusMeters == rhs.radiusMeters
      && lhs.minimumRadius == rhs.minimumRadius
      && lhs.maximumRadius == rhs.maximumRadius
      && lhs.isEnabled == rhs.isEnabled
  }
}
