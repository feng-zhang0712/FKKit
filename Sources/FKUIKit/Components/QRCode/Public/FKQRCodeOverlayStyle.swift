import CoreGraphics
import Foundation

/// Visual styling for the scanner overlay frame.
public struct FKQRCodeOverlayStyle: Sendable, Equatable {
  /// Side length of the square scan region as a fraction of the shorter preview dimension.
  public var scanRegionRelativeSize: CGFloat
  /// Length of each corner bracket line.
  public var cornerLength: CGFloat
  /// Stroke width of corner brackets.
  public var cornerLineWidth: CGFloat
  /// Whether to animate a horizontal scan line inside the frame.
  public var showsScanLineAnimation: Bool

  /// Default square frame with animated scan line.
  public static let `default` = FKQRCodeOverlayStyle(
    scanRegionRelativeSize: 0.68,
    cornerLength: 22,
    cornerLineWidth: 4,
    showsScanLineAnimation: true
  )

  /// Creates overlay styling.
  public init(
    scanRegionRelativeSize: CGFloat = 0.68,
    cornerLength: CGFloat = 22,
    cornerLineWidth: CGFloat = 4,
    showsScanLineAnimation: Bool = true
  ) {
    self.scanRegionRelativeSize = scanRegionRelativeSize
    self.cornerLength = cornerLength
    self.cornerLineWidth = cornerLineWidth
    self.showsScanLineAnimation = showsScanLineAnimation
  }
}
