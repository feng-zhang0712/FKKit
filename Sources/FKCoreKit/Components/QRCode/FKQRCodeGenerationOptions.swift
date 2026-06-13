#if canImport(UIKit)
import UIKit

/// Visual and encoding options for ``FKQRCodeGenerator``.
///
/// - Note: Marked `@unchecked Sendable` because `UIColor` and nested logo types are not `Sendable`.
public struct FKQRCodeGenerationOptions: @unchecked Sendable, Equatable {
  /// Target output size in points.
  public var size: CGSize
  /// Error-correction level; automatically upgraded to `.H` when `logo` is set.
  public var correctionLevel: FKQRCodeCorrectionLevel
  /// Module (foreground) color.
  public var foregroundColor: UIColor
  /// Background color.
  public var backgroundColor: UIColor
  /// Optional center logo; only applied by ``FKQRCodeGenerator/makeImage(from:options:)``.
  public var logo: FKQRCodeLogoEmbedding?

  /// Default 256×256 QR with medium correction and system foreground/background colors.
  public static let `default` = FKQRCodeGenerationOptions(
    size: CGSize(width: 256, height: 256),
    correctionLevel: .M,
    foregroundColor: .label,
    backgroundColor: .systemBackground,
    logo: nil
  )

  /// Creates generation options.
  public init(
    size: CGSize = CGSize(width: 256, height: 256),
    correctionLevel: FKQRCodeCorrectionLevel = .M,
    foregroundColor: UIColor = .label,
    backgroundColor: UIColor = .systemBackground,
    logo: FKQRCodeLogoEmbedding? = nil
  ) {
    self.size = size
    self.correctionLevel = correctionLevel
    self.foregroundColor = foregroundColor
    self.backgroundColor = backgroundColor
    self.logo = logo
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.size == rhs.size
      && lhs.correctionLevel == rhs.correctionLevel
      && lhs.foregroundColor.cgColor == rhs.foregroundColor.cgColor
      && lhs.backgroundColor.cgColor == rhs.backgroundColor.cgColor
      && lhs.logo == rhs.logo
  }
}
#endif
