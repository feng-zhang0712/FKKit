import UIKit

enum FKRatingLayoutEngine {
  struct Metrics: Equatable {
    var itemFrames: [CGRect]
    var iconsRect: CGRect
    var labelFrame: CGRect?
  }

  static func metrics(
    in bounds: CGRect,
    configuration: FKRatingConfiguration,
    labelSize: CGSize,
    layoutDirection: UIUserInterfaceLayoutDirection
  ) -> Metrics {
    let insets = configuration.layout.contentInsets
    let available = bounds.inset(by: insets)
    let itemCount = configuration.layout.itemCount
    let itemSize = configuration.layout.itemSize
    let spacing = configuration.layout.itemSpacing

    let iconsWidth = CGFloat(itemCount) * itemSize.width + CGFloat(max(0, itemCount - 1)) * spacing
    let iconsHeight = itemSize.height

    let contentHeight: CGFloat = {
      switch configuration.layout.labelPlacement {
      case .none:
        return iconsHeight
      case .trailing:
        return max(iconsHeight, labelSize.height)
      case .bottom:
        guard labelSize != .zero else { return iconsHeight }
        return iconsHeight + configuration.layout.labelSpacing + labelSize.height
      }
    }()

    let iconsOriginY: CGFloat = {
      switch configuration.layout.labelPlacement {
      case .bottom:
        // Top-align icons so the caption fits below without clipping.
        return available.minY
      case .none, .trailing:
        return available.minY + max(0, (available.height - contentHeight) * 0.5)
      }
    }()

    var itemFrames: [CGRect] = []
    itemFrames.reserveCapacity(itemCount)

    let ltrOriginX: CGFloat = {
      switch configuration.layout.labelPlacement {
      case .none, .bottom:
        return available.minX + max(0, (available.width - iconsWidth) * 0.5)
      case .trailing:
        let labelWidth = labelSize.width + configuration.layout.labelSpacing
        let clusterWidth = iconsWidth + (labelSize == .zero ? 0 : labelWidth)
        return available.minX + max(0, (available.width - clusterWidth) * 0.5)
      }
    }()

    for index in 0 ..< itemCount {
      let logicalIndex = layoutDirection == .rightToLeft ? (itemCount - 1 - index) : index
      let x = ltrOriginX + CGFloat(logicalIndex) * (itemSize.width + spacing)
      itemFrames.append(CGRect(x: x, y: iconsOriginY, width: itemSize.width, height: itemSize.height))
    }

    if layoutDirection == .rightToLeft {
      itemFrames.sort { $0.minX < $1.minX }
    }

    let iconsRect = CGRect(
      x: itemFrames.first?.minX ?? available.minX,
      y: iconsOriginY,
      width: iconsWidth,
      height: iconsHeight
    )

    let labelFrame: CGRect? = {
      guard configuration.layout.labelPlacement != .none, labelSize != .zero else { return nil }
      switch configuration.layout.labelPlacement {
      case .none:
        return nil
      case .trailing:
        let x = iconsRect.maxX + configuration.layout.labelSpacing
        let y = iconsOriginY + (iconsHeight - labelSize.height) * 0.5
        return CGRect(x: x, y: y, width: labelSize.width, height: labelSize.height)
      case .bottom:
        let x = iconsRect.minX + max(0, (iconsWidth - labelSize.width) * 0.5)
        let y = iconsRect.maxY + configuration.layout.labelSpacing
        return CGRect(x: x, y: y, width: labelSize.width, height: labelSize.height)
      }
    }()

    return Metrics(itemFrames: itemFrames, iconsRect: iconsRect, labelFrame: labelFrame)
  }

  static func intrinsicContentSize(
    configuration: FKRatingConfiguration,
    labelSize: CGSize
  ) -> CGSize {
    let insets = configuration.layout.contentInsets
    let itemCount = configuration.layout.itemCount
    let itemSize = configuration.layout.itemSize
    let spacing = configuration.layout.itemSpacing
    let iconsWidth = CGFloat(itemCount) * itemSize.width + CGFloat(max(0, itemCount - 1)) * spacing
    let iconsHeight = itemSize.height

    var width = iconsWidth
    var height = iconsHeight

    switch configuration.layout.labelPlacement {
    case .none:
      break
    case .trailing:
      if labelSize != .zero {
        width += configuration.layout.labelSpacing + labelSize.width
      }
      height = max(height, labelSize.height)
    case .bottom:
      if labelSize != .zero {
        height += configuration.layout.labelSpacing + labelSize.height
        width = max(width, labelSize.width)
      }
    }

    return CGSize(
      width: width + insets.leading + insets.trailing,
      height: height + insets.top + insets.bottom
    )
  }

  static func value(
    at point: CGPoint,
    in metrics: Metrics,
    minimumValue: Double,
    maximumValue: Double,
    layoutDirection: UIUserInterfaceLayoutDirection
  ) -> Double {
    let rect = metrics.iconsRect
    guard rect.width > 0 else { return minimumValue }

    let localX: CGFloat = {
      let raw = point.x - rect.minX
      if layoutDirection == .rightToLeft {
        return rect.width - raw
      }
      return raw
    }()

    let fraction = Double(min(max(localX / rect.width, 0), 1))
    return minimumValue + fraction * (maximumValue - minimumValue)
  }

  static func expandedHitFrame(for itemFrame: CGRect, minimumSize: CGSize) -> CGRect {
    let target = CGSize(
      width: max(itemFrame.width, minimumSize.width),
      height: max(itemFrame.height, minimumSize.height)
    )
    return CGRect(
      x: itemFrame.midX - target.width * 0.5,
      y: itemFrame.midY - target.height * 0.5,
      width: target.width,
      height: target.height
    )
  }
}

extension FKRatingLayoutEngine {
  static func fillFraction(
    forItemAt index: Int,
    value: Double,
    minimumValue: Double,
    maximumValue: Double,
    itemCount: Int
  ) -> CGFloat {
    guard itemCount > 0, maximumValue > minimumValue else { return 0 }
    let span = (maximumValue - minimumValue) / Double(itemCount)
    let lowerBound = minimumValue + Double(index) * span
    let fraction = (value - lowerBound) / span
    return CGFloat(min(max(fraction, 0), 1))
  }
}

private extension CGRect {
  func inset(by insets: NSDirectionalEdgeInsets) -> CGRect {
    CGRect(
      x: minX + insets.leading,
      y: minY + insets.top,
      width: width - insets.leading - insets.trailing,
      height: height - insets.top - insets.bottom
    )
  }
}
