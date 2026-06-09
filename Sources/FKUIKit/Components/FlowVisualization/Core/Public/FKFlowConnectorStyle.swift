import QuartzCore
import UIKit

/// Stroke styling for connectors between flow nodes.
public struct FKFlowConnectorStyle: @unchecked Sendable, Equatable {
  /// Line thickness in points.
  public var thickness: CGFloat
  /// Color when the leading step is completed (or treated as completed).
  public var completedColor: UIColor
  /// Color for inactive segments.
  public var upcomingColor: UIColor
  /// Optional dash pattern; `nil` draws a solid line.
  public var dashPattern: [CGFloat]?
  /// Line cap applied to connector paths.
  public var capStyle: CAShapeLayerLineCap

  public init(
    thickness: CGFloat = 2,
    completedColor: UIColor = .systemBlue,
    upcomingColor: UIColor = .tertiaryLabel,
    dashPattern: [CGFloat]? = nil,
    capStyle: CAShapeLayerLineCap = .round
  ) {
    self.thickness = max(0.5, thickness)
    self.completedColor = completedColor
    self.upcomingColor = upcomingColor
    self.dashPattern = dashPattern
    self.capStyle = capStyle
  }
}
