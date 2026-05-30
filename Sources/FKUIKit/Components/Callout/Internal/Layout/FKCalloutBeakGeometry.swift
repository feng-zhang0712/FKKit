import UIKit

enum FKCalloutBeakGeometry {
  struct LayoutMetrics: Equatable {
    var beakEdge: FKCalloutPlacement.BeakEdge
    var beakCenterAlongEdge: CGFloat
    var beakWidth: CGFloat
    var beakHeight: CGFloat
    var cornerRadius: CGFloat
    var beakStyle: FKCalloutBeakStyle = .isosceles
  }

  static func bodyPath(bounds: CGRect, metrics: LayoutMetrics) -> UIBezierPath {
    let radius = min(metrics.cornerRadius, min(bounds.width, bounds.height) * 0.25)
    let beakH = metrics.beakHeight
    let insetBody: CGRect = {
      switch metrics.beakEdge {
      case .top:
        return bounds.inset(by: UIEdgeInsets(top: beakH, left: 0, bottom: 0, right: 0))
      case .bottom:
        return bounds.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: beakH, right: 0))
      case .leading:
        return bounds.inset(by: UIEdgeInsets(top: 0, left: beakH, bottom: 0, right: 0))
      case .trailing:
        return bounds.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: beakH))
      }
    }()
    return UIBezierPath(roundedRect: insetBody, cornerRadius: radius)
  }

  static func beakPath(bounds: CGRect, metrics: LayoutMetrics) -> UIBezierPath {
    switch metrics.beakStyle {
    case .isosceles:
      return isoscelesBeakPath(bounds: bounds, metrics: metrics)
    case .equilateral:
      return equilateralBeakPath(bounds: bounds, metrics: metrics)
    case let .rightAngle(corner, apexAlongBase):
      return rightAngleBeakPath(bounds: bounds, metrics: metrics, corner: corner, apexAlongBase: apexAlongBase)
    case let .polygon(vertices):
      return polygonBeakPath(bounds: bounds, metrics: metrics, vertices: vertices)
    }
  }

  static func unifiedBubblePath(bounds: CGRect, metrics: LayoutMetrics, includesBeak: Bool = true) -> CGPath {
    let path = UIBezierPath()
    path.append(bodyPath(bounds: bounds, metrics: metrics))
    if includesBeak {
      path.append(beakPath(bounds: bounds, metrics: metrics))
    }
    return path.cgPath
  }

  static func beakFrame(bounds: CGRect, metrics: LayoutMetrics) -> CGRect {
    let center = metrics.beakCenterAlongEdge
    let width = metrics.beakWidth
    let height = metrics.beakHeight
    switch metrics.beakEdge {
    case .top:
      return CGRect(x: center - width * 0.5, y: 0, width: width, height: height)
    case .bottom:
      return CGRect(x: center - width * 0.5, y: bounds.maxY - height, width: width, height: height)
    case .leading:
      return CGRect(x: 0, y: center - width * 0.5, width: height, height: width)
    case .trailing:
      return CGRect(x: bounds.maxX - height, y: center - width * 0.5, width: height, height: width)
    }
  }

  /// Content layout guide inset that reserves space for the beak inside `bounds`.
  static func contentLayoutGuideInsets(
    bubbleBounds: CGRect,
    metrics: LayoutMetrics,
    contentInsets: NSDirectionalEdgeInsets
  ) -> UIEdgeInsets {
    let directional = NSDirectionalEdgeInsets(
      top: contentInsets.top,
      leading: contentInsets.leading,
      bottom: contentInsets.bottom,
      trailing: contentInsets.trailing
    )
    var base = UIEdgeInsets(
      top: directional.top,
      left: directional.leading,
      bottom: directional.bottom,
      right: directional.trailing
    )
    switch metrics.beakEdge {
    case .top:
      base.top += metrics.beakHeight
    case .bottom:
      base.bottom += metrics.beakHeight
    case .leading:
      base.left += metrics.beakHeight
    case .trailing:
      base.right += metrics.beakHeight
    }
    return base
  }

  private static func isoscelesBeakPath(bounds: CGRect, metrics: LayoutMetrics) -> UIBezierPath {
    let (tip, baseLeading, baseTrailing) = baseBeakPoints(bounds: bounds, metrics: metrics)
    let beak = UIBezierPath()
    beak.move(to: baseLeading)
    beak.addLine(to: tip)
    beak.addLine(to: baseTrailing)
    beak.close()
    return beak
  }

  private static func equilateralBeakPath(bounds: CGRect, metrics: LayoutMetrics) -> UIBezierPath {
    var adjusted = metrics
    adjusted.beakHeight = metrics.beakWidth * sqrt(3) * 0.5
    return isoscelesBeakPath(bounds: bounds, metrics: adjusted)
  }

  private static func rightAngleBeakPath(
    bounds: CGRect,
    metrics: LayoutMetrics,
    corner: FKCalloutBeakRightAngleCorner,
    apexAlongBase: CGFloat
  ) -> UIBezierPath {
    let (_, baseLeading, baseTrailing) = baseBeakPoints(bounds: bounds, metrics: metrics)
    let clamped = min(max(apexAlongBase, 0), 1)
    let tipOnBase = CGPoint(
      x: baseLeading.x + (baseTrailing.x - baseLeading.x) * clamped,
      y: baseLeading.y + (baseTrailing.y - baseLeading.y) * clamped
    )
    let outwardTip = outwardTipPoint(from: tipOnBase, edge: metrics.beakEdge, bounds: bounds)
    let beak = UIBezierPath()
    switch corner {
    case .leading:
      beak.move(to: baseLeading)
      beak.addLine(to: baseTrailing)
      beak.addLine(to: outwardTip)
    case .trailing:
      beak.move(to: baseTrailing)
      beak.addLine(to: baseLeading)
      beak.addLine(to: outwardTip)
    }
    beak.close()
    return beak
  }

  private static func outwardTipPoint(
    from basePoint: CGPoint,
    edge: FKCalloutPlacement.BeakEdge,
    bounds: CGRect
  ) -> CGPoint {
    switch edge {
    case .top:
      return CGPoint(x: basePoint.x, y: 0)
    case .bottom:
      return CGPoint(x: basePoint.x, y: bounds.maxY)
    case .leading:
      return CGPoint(x: 0, y: basePoint.y)
    case .trailing:
      return CGPoint(x: bounds.maxX, y: basePoint.y)
    }
  }

  private static func polygonBeakPath(bounds: CGRect, metrics: LayoutMetrics, vertices: [CGPoint]) -> UIBezierPath {
    guard vertices.count >= 3 else {
      return isoscelesBeakPath(bounds: bounds, metrics: metrics)
    }
    let slot = beakFrame(bounds: bounds, metrics: metrics)
    let beak = UIBezierPath()
    for (index, vertex) in vertices.enumerated() {
      let point = mapNormalizedBeakPoint(vertex, slot: slot, edge: metrics.beakEdge)
      if index == 0 {
        beak.move(to: point)
      } else {
        beak.addLine(to: point)
      }
    }
    beak.close()
    return beak
  }

  private static func baseBeakPoints(bounds: CGRect, metrics: LayoutMetrics) -> (tip: CGPoint, baseLeading: CGPoint, baseTrailing: CGPoint) {
    let center = metrics.beakCenterAlongEdge
    let half = metrics.beakWidth * 0.5
    let beakH = metrics.beakHeight
    switch metrics.beakEdge {
    case .top:
      return (
        CGPoint(x: center, y: 0),
        CGPoint(x: center - half, y: beakH),
        CGPoint(x: center + half, y: beakH)
      )
    case .bottom:
      return (
        CGPoint(x: center, y: bounds.maxY),
        CGPoint(x: center - half, y: bounds.maxY - beakH),
        CGPoint(x: center + half, y: bounds.maxY - beakH)
      )
    case .leading:
      return (
        CGPoint(x: 0, y: center),
        CGPoint(x: beakH, y: center - half),
        CGPoint(x: beakH, y: center + half)
      )
    case .trailing:
      return (
        CGPoint(x: bounds.maxX, y: center),
        CGPoint(x: bounds.maxX - beakH, y: center - half),
        CGPoint(x: bounds.maxX - beakH, y: center + half)
      )
    }
  }

  private static func mapNormalizedBeakPoint(
    _ vertex: CGPoint,
    slot: CGRect,
    edge: FKCalloutPlacement.BeakEdge
  ) -> CGPoint {
    let clampedX = min(max(vertex.x, 0), 1)
    let clampedY = min(max(vertex.y, 0), 1)
    switch edge {
    case .top:
      return CGPoint(x: slot.minX + clampedX * slot.width, y: slot.maxY - clampedY * slot.height)
    case .bottom:
      return CGPoint(x: slot.minX + clampedX * slot.width, y: slot.minY + clampedY * slot.height)
    case .leading:
      return CGPoint(x: slot.maxX - clampedY * slot.width, y: slot.minY + clampedX * slot.height)
    case .trailing:
      return CGPoint(x: slot.minX + clampedY * slot.width, y: slot.minY + clampedX * slot.height)
    }
  }
}
