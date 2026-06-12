import UIKit

enum FKAvatarGroupLayoutEngine {
  struct Metrics: Equatable {
    var avatarFrames: [CGRect]
    var overflowFrame: CGRect?
    var totalSize: CGSize
  }

  static func layout(
    visibleAvatarCount: Int,
    showsOverflow: Bool,
    avatarDiameter: CGFloat,
    overlap: CGFloat,
    overflowDiameter: CGFloat,
    direction: FKAvatarGroupDirection,
    isRTL: Bool
  ) -> Metrics {
    let count = max(0, visibleAvatarCount)
    let step = avatarDiameter + overlap
    let overflowWidth = showsOverflow ? overflowDiameter : 0
    let totalWidth: CGFloat
    if count == 0 {
      totalWidth = overflowWidth
    } else {
      totalWidth = CGFloat(count) * avatarDiameter + CGFloat(max(0, count - 1)) * overlap + (showsOverflow ? overlap + overflowWidth : 0)
    }
    let totalSize = CGSize(width: max(0, totalWidth), height: avatarDiameter)

    var avatarFrames: [CGRect] = []
    avatarFrames.reserveCapacity(count)

    let leadingToTrailing: Bool
    switch direction {
    case .leadingToTrailing:
      leadingToTrailing = !isRTL
    case .trailingToLeading:
      leadingToTrailing = isRTL
    }

    for index in 0 ..< count {
      let x: CGFloat
      if leadingToTrailing {
        x = CGFloat(index) * step
      } else {
        x = totalWidth - CGFloat(index + 1) * avatarDiameter - CGFloat(index) * overlap - (showsOverflow ? overlap + overflowWidth : 0)
      }
      avatarFrames.append(CGRect(x: x, y: 0, width: avatarDiameter, height: avatarDiameter))
    }

    var overflowFrame: CGRect?
    if showsOverflow {
      let x: CGFloat
      if leadingToTrailing {
        x = CGFloat(count) * step
      } else {
        x = 0
      }
      overflowFrame = CGRect(x: x, y: 0, width: overflowDiameter, height: avatarDiameter)
    }

    return Metrics(avatarFrames: avatarFrames, overflowFrame: overflowFrame, totalSize: totalSize)
  }
}
