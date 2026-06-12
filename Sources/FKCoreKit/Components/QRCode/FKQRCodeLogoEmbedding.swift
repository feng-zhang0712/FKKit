#if canImport(UIKit)
import UIKit

/// Optional center logo overlay applied when generating a QR bitmap.
///
/// - Note: Marked `@unchecked Sendable` because `UIImage` is not `Sendable`; treat as a main-thread snapshot.
public struct FKQRCodeLogoEmbedding: @unchecked Sendable, Equatable {
  /// Logo image drawn at the center of the QR code.
  public var image: UIImage
  /// Maximum logo side length as a fraction of the QR side (clamped to `0.22`).
  public var maxRelativeSize: CGFloat
  /// Optional corner radius applied to the logo draw rect.
  public var cornerRadius: CGFloat

  /// Creates a logo embedding configuration.
  ///
  /// - Parameters:
  ///   - image: Center logo image.
  ///   - maxRelativeSize: Cap relative to QR size; values above `0.22` are clamped.
  ///   - cornerRadius: Corner radius for the logo rect; `0` draws a square logo.
  public init(
    image: UIImage,
    maxRelativeSize: CGFloat = 0.22,
    cornerRadius: CGFloat = 0
  ) {
    self.image = image
    self.maxRelativeSize = maxRelativeSize
    self.cornerRadius = cornerRadius
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.maxRelativeSize == rhs.maxRelativeSize
      && lhs.cornerRadius == rhs.cornerRadius
      && lhs.image.pngData() == rhs.image.pngData()
  }
}
#endif
