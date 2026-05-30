import UIKit

/// Icon descriptor for ``FKCalloutContent/iconMessage(icon:symbolName:message:)``.
public struct FKCalloutIcon: Sendable, Equatable {
  /// Template image icon.
  public var image: UIImage?
  /// SF Symbol name used when ``image`` is `nil`.
  public var symbolName: String?
  /// Icon tint override.
  public var tintColor: UIColor?

  /// Creates an icon payload.
  public init(image: UIImage? = nil, symbolName: String? = nil, tintColor: UIColor? = nil) {
    self.image = image
    self.symbolName = symbolName
    self.tintColor = tintColor
  }
}
