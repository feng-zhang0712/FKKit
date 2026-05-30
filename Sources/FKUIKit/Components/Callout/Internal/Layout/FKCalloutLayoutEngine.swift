import UIKit

enum FKCalloutLayoutEngine {
  struct Result: Equatable {
    var frame: CGRect
    var placement: FKCalloutPlacement
    var beakCenterAlongEdge: CGFloat
  }

  private static let automaticCandidates: [FKCalloutPlacement] = [.top, .bottom, .leading, .trailing]

  static func layout(
    anchorRectInWindow: CGRect,
    bubbleSize: CGSize,
    placement: FKCalloutPlacement,
    anchorSpacing: CGFloat,
    anchorAlignment: FKCalloutAnchorAlignment,
    beakOffset: FKCalloutBeakOffset,
    beakWidth: CGFloat,
    cornerRadius: CGFloat,
    beakCornerInset: CGFloat,
    layoutDirection: UIUserInterfaceLayoutDirection,
    safeAreaInsets: UIEdgeInsets,
    containerBounds: CGRect,
    screenEdgeMargin: CGFloat,
    flipsWhenNeeded: Bool,
    bottomObstruction: CGFloat = 0
  ) -> Result {
    let safeLayoutBounds = layoutBounds(
      containerBounds: containerBounds,
      safeAreaInsets: safeAreaInsets,
      screenEdgeMargin: screenEdgeMargin,
      bottomObstruction: bottomObstruction
    )

    let candidates = candidatePlacements(for: placement, flipsWhenNeeded: flipsWhenNeeded)
    var best: Result?
    var bestScore: CGFloat = .greatestFiniteMagnitude

    for candidate in candidates {
      let proposed = proposedFrame(
        anchorRect: anchorRectInWindow,
        bubbleSize: bubbleSize,
        placement: candidate,
        anchorSpacing: anchorSpacing,
        anchorAlignment: anchorAlignment
      )
      let clamped = clampFrame(proposed, to: safeLayoutBounds)
      let beakCenter = resolvedBeakCenter(
        anchorRect: anchorRectInWindow,
        bubbleFrame: clamped,
        placement: candidate,
        beakOffset: beakOffset,
        beakWidth: beakWidth,
        cornerRadius: cornerRadius,
        beakCornerInset: beakCornerInset,
        layoutDirection: layoutDirection
      )
      let score = placementScore(
        frame: clamped,
        layoutBounds: safeLayoutBounds,
        placement: candidate,
        requestedPlacement: placement,
        anchorRect: anchorRectInWindow,
        bubbleSize: bubbleSize,
        anchorSpacing: anchorSpacing
      )
      if score < bestScore {
        bestScore = score
        best = Result(frame: clamped, placement: candidate, beakCenterAlongEdge: beakCenter)
      }
    }

    let fallbackPlacement: FKCalloutPlacement = {
      if placement == .automatic {
        let topSpace = availableSpace(
          anchorRect: anchorRectInWindow,
          placement: .top,
          layoutBounds: safeLayoutBounds,
          anchorSpacing: anchorSpacing
        )
        let bottomSpace = availableSpace(
          anchorRect: anchorRectInWindow,
          placement: .bottom,
          layoutBounds: safeLayoutBounds,
          anchorSpacing: anchorSpacing
        )
        return bottomSpace >= topSpace ? .bottom : .top
      }
      return placement
    }()
    let fallbackFrame = clampFrame(
      proposedFrame(
        anchorRect: anchorRectInWindow,
        bubbleSize: bubbleSize,
        placement: fallbackPlacement,
        anchorSpacing: anchorSpacing,
        anchorAlignment: anchorAlignment
      ),
      to: safeLayoutBounds
    )
    let resolved = best ?? Result(
      frame: fallbackFrame,
      placement: fallbackPlacement,
      beakCenterAlongEdge: resolvedBeakCenter(
        anchorRect: anchorRectInWindow,
        bubbleFrame: fallbackFrame,
        placement: fallbackPlacement,
        beakOffset: beakOffset,
        beakWidth: beakWidth,
        cornerRadius: cornerRadius,
        beakCornerInset: beakCornerInset,
        layoutDirection: layoutDirection
      )
    )
    let clampedFrame = clampFrame(resolved.frame, to: safeLayoutBounds)
    return Result(
      frame: clampedFrame,
      placement: resolved.placement,
      beakCenterAlongEdge: resolvedBeakCenter(
        anchorRect: anchorRectInWindow,
        bubbleFrame: clampedFrame,
        placement: resolved.placement,
        beakOffset: beakOffset,
        beakWidth: beakWidth,
        cornerRadius: cornerRadius,
        beakCornerInset: beakCornerInset,
        layoutDirection: layoutDirection
      )
    )
  }

  private static func candidatePlacements(
    for placement: FKCalloutPlacement,
    flipsWhenNeeded: Bool
  ) -> [FKCalloutPlacement] {
    if placement == .automatic {
      return automaticCandidates
    }
    if flipsWhenNeeded {
      return [placement, placement.flipped]
    }
    return [placement]
  }

  private static func placementScore(
    frame: CGRect,
    layoutBounds: CGRect,
    placement: FKCalloutPlacement,
    requestedPlacement: FKCalloutPlacement,
    anchorRect: CGRect,
    bubbleSize: CGSize,
    anchorSpacing: CGFloat
  ) -> CGFloat {
    let overflow = overflowPenalty(frame: frame, layoutBounds: layoutBounds)
    if requestedPlacement == .automatic {
      let available = availableSpace(
        anchorRect: anchorRect,
        placement: placement,
        layoutBounds: layoutBounds,
        anchorSpacing: anchorSpacing
      )
      let required = requiredSpace(for: placement, bubbleSize: bubbleSize)
      let deficit = max(0, required - available)
      // Prefer the side with more room; penalize sides that cannot fit the bubble.
      return overflow + deficit * 1_000 - available
    }
    if placement == requestedPlacement {
      return overflow
    }
    if placement == requestedPlacement.flipped {
      // Flip only when overflow is worse on the requested side (overflow is primary).
      return overflow + 1
    }
    return overflow + 1_000
  }

  /// Bounds used for clamping bubble position and measuring available width.
  static func layoutBounds(
    containerBounds: CGRect,
    safeAreaInsets: UIEdgeInsets,
    screenEdgeMargin: CGFloat,
    bottomObstruction: CGFloat = 0
  ) -> CGRect {
    var rect = containerBounds
      .inset(by: safeAreaInsets)
      .inset(by: UIEdgeInsets(
        top: screenEdgeMargin,
        left: screenEdgeMargin,
        bottom: screenEdgeMargin,
        right: screenEdgeMargin
      ))
    if bottomObstruction > 0 {
      rect.size.height = max(0, rect.size.height - bottomObstruction)
    }
    return rect
  }

  static func resolvedBeakCenter(
    anchorRect: CGRect,
    bubbleFrame: CGRect,
    placement: FKCalloutPlacement,
    beakOffset: FKCalloutBeakOffset,
    beakWidth: CGFloat,
    cornerRadius: CGFloat,
    beakCornerInset: CGFloat,
    layoutDirection: UIUserInterfaceLayoutDirection
  ) -> CGFloat {
    let edgeLength: CGFloat
    let isHorizontalEdge: Bool
    switch placement.beakEdge {
    case .top, .bottom:
      edgeLength = bubbleFrame.width
      isHorizontalEdge = true
    case .leading, .trailing:
      edgeLength = bubbleFrame.height
      isHorizontalEdge = false
    }

    let margin = max(
      beakWidth * 0.5 + 2,
      cornerRadius + 2,
      beakCornerInset + beakWidth * 0.5
    )
    let usableLength = max(edgeLength - margin * 2, 1)

    switch beakOffset {
    case .automatic:
      return clampBeakCenter(
        automaticBeakCenter(
          anchorRect: anchorRect,
          bubbleFrame: bubbleFrame,
          placement: placement,
          margin: margin,
          edgeLength: edgeLength,
          isHorizontalEdge: isHorizontalEdge,
          layoutDirection: layoutDirection
        ),
        edgeLength: edgeLength,
        margin: margin
      )
    case let .fraction(value, reference):
      let clamped = min(max(value, 0), 1)
      let center: CGFloat
      switch reference {
      case .bubbleEdge:
        center = margin + usableLength * clamped
      case .anchor:
        let anchorOrigin = anchorReferenceOnEdge(
          anchorRect: anchorRect,
          bubbleFrame: bubbleFrame,
          placement: placement,
          margin: margin,
          edgeLength: edgeLength,
          isHorizontalEdge: isHorizontalEdge,
          layoutDirection: layoutDirection
        )
        let spanEnd = edgeLength - margin
        center = anchorOrigin + (spanEnd - anchorOrigin) * clamped
      }
      return clampBeakCenter(center, edgeLength: edgeLength, margin: margin)
    case let .fixed(value, reference):
      let center: CGFloat
      switch reference {
      case .bubbleEdge:
        center = margin + value
      case .anchor:
        let anchorOrigin = anchorReferenceOnEdge(
          anchorRect: anchorRect,
          bubbleFrame: bubbleFrame,
          placement: placement,
          margin: margin,
          edgeLength: edgeLength,
          isHorizontalEdge: isHorizontalEdge,
          layoutDirection: layoutDirection
        )
        center = anchorOrigin + value
      }
      return clampBeakCenter(center, edgeLength: edgeLength, margin: margin)
    }
  }

  private static func automaticBeakCenter(
    anchorRect: CGRect,
    bubbleFrame: CGRect,
    placement: FKCalloutPlacement,
    margin: CGFloat,
    edgeLength: CGFloat,
    isHorizontalEdge: Bool,
    layoutDirection: UIUserInterfaceLayoutDirection
  ) -> CGFloat {
    let proposed = projectedAnchorCoordinateOnBeakEdge(
      anchorRect: anchorRect,
      bubbleFrame: bubbleFrame,
      placement: placement,
      beakAlignment: placement.preferredBeakAlignment,
      isHorizontalEdge: isHorizontalEdge,
      layoutDirection: layoutDirection
    )
    return clampBeakCenter(proposed, edgeLength: edgeLength, margin: margin)
  }

  private static func anchorReferenceOnEdge(
    anchorRect: CGRect,
    bubbleFrame: CGRect,
    placement: FKCalloutPlacement,
    margin: CGFloat,
    edgeLength: CGFloat,
    isHorizontalEdge: Bool,
    layoutDirection: UIUserInterfaceLayoutDirection
  ) -> CGFloat {
    let proposed = projectedAnchorCoordinateOnBeakEdge(
      anchorRect: anchorRect,
      bubbleFrame: bubbleFrame,
      placement: placement,
      beakAlignment: placement.preferredBeakAlignment,
      isHorizontalEdge: isHorizontalEdge,
      layoutDirection: layoutDirection
    )
    return clampBeakCenter(proposed, edgeLength: edgeLength, margin: margin)
  }

  /// Maps an anchor feature point onto the bubble beak edge (X for top/bottom, Y for leading/trailing).
  private static func projectedAnchorCoordinateOnBeakEdge(
    anchorRect: CGRect,
    bubbleFrame: CGRect,
    placement: FKCalloutPlacement,
    beakAlignment: FKCalloutPlacement.BeakAlignment,
    isHorizontalEdge: Bool,
    layoutDirection: UIUserInterfaceLayoutDirection
  ) -> CGFloat {
    switch beakAlignment {
    case .center:
      let anchorCenter = CGPoint(x: anchorRect.midX, y: anchorRect.midY)
      switch placement.beakEdge {
      case .top, .bottom:
        return anchorCenter.x - bubbleFrame.minX
      case .leading, .trailing:
        return anchorCenter.y - bubbleFrame.minY
      }
    case .leading:
      if isHorizontalEdge {
        let anchorX = layoutDirection == .rightToLeft ? anchorRect.maxX : anchorRect.minX
        return anchorX - bubbleFrame.minX
      }
      return anchorRect.minY - bubbleFrame.minY
    case .trailing:
      if isHorizontalEdge {
        let anchorX = layoutDirection == .rightToLeft ? anchorRect.minX : anchorRect.maxX
        return anchorX - bubbleFrame.minX
      }
      return anchorRect.maxY - bubbleFrame.minY
    }
  }

  private static func clampBeakCenter(_ proposed: CGFloat, edgeLength: CGFloat, margin: CGFloat) -> CGFloat {
    min(max(proposed, margin), edgeLength - margin)
  }

  private static func proposedFrame(
    anchorRect: CGRect,
    bubbleSize: CGSize,
    placement: FKCalloutPlacement,
    anchorSpacing: CGFloat,
    anchorAlignment: FKCalloutAnchorAlignment
  ) -> CGRect {
    let alignment = effectiveAnchorAlignment(placement: placement, anchorAlignment: anchorAlignment)
    let gap = anchorSpacing
    var origin = CGPoint.zero
    switch placement {
    case .automatic, .top, .topLeading, .topTrailing:
      origin.y = anchorRect.minY - gap - bubbleSize.height
      origin.x = alignedOrigin(
        anchorStart: anchorRect.minX,
        anchorEnd: anchorRect.maxX,
        bubbleLength: bubbleSize.width,
        alignment: alignment
      )
    case .bottom, .bottomLeading, .bottomTrailing:
      origin.y = anchorRect.maxY + gap
      origin.x = alignedOrigin(
        anchorStart: anchorRect.minX,
        anchorEnd: anchorRect.maxX,
        bubbleLength: bubbleSize.width,
        alignment: alignment
      )
    case .leading, .leadingTop, .leadingBottom:
      origin.x = anchorRect.minX - gap - bubbleSize.width
      origin.y = alignedOrigin(
        anchorStart: anchorRect.minY,
        anchorEnd: anchorRect.maxY,
        bubbleLength: bubbleSize.height,
        alignment: alignment
      )
    case .trailing, .trailingTop, .trailingBottom:
      origin.x = anchorRect.maxX + gap
      origin.y = alignedOrigin(
        anchorStart: anchorRect.minY,
        anchorEnd: anchorRect.maxY,
        bubbleLength: bubbleSize.height,
        alignment: alignment
      )
    }
    return CGRect(origin: origin, size: bubbleSize).integral
  }

  private static func effectiveAnchorAlignment(
    placement: FKCalloutPlacement,
    anchorAlignment: FKCalloutAnchorAlignment
  ) -> FKCalloutAnchorAlignment {
    switch placement {
    case .topLeading, .bottomLeading:
      return .leading
    case .topTrailing, .bottomTrailing:
      return .trailing
    case .leadingTop, .trailingTop:
      return .leading
    case .leadingBottom, .trailingBottom:
      return .trailing
    default:
      return anchorAlignment
    }
  }

  private static func availableSpace(
    anchorRect: CGRect,
    placement: FKCalloutPlacement,
    layoutBounds: CGRect,
    anchorSpacing: CGFloat
  ) -> CGFloat {
    switch placement {
    case .top, .topLeading, .topTrailing:
      return max(0, anchorRect.minY - layoutBounds.minY - anchorSpacing)
    case .bottom, .bottomLeading, .bottomTrailing:
      return max(0, layoutBounds.maxY - anchorRect.maxY - anchorSpacing)
    case .leading, .leadingTop, .leadingBottom:
      return max(0, anchorRect.minX - layoutBounds.minX - anchorSpacing)
    case .trailing, .trailingTop, .trailingBottom:
      return max(0, layoutBounds.maxX - anchorRect.maxX - anchorSpacing)
    case .automatic:
      return 0
    }
  }

  private static func requiredSpace(for placement: FKCalloutPlacement, bubbleSize: CGSize) -> CGFloat {
    switch placement {
    case .top, .topLeading, .topTrailing, .bottom, .bottomLeading, .bottomTrailing:
      return bubbleSize.height
    case .leading, .leadingTop, .leadingBottom, .trailing, .trailingTop, .trailingBottom:
      return bubbleSize.width
    case .automatic:
      return 0
    }
  }

  private static func alignedOrigin(
    anchorStart: CGFloat,
    anchorEnd: CGFloat,
    bubbleLength: CGFloat,
    alignment: FKCalloutAnchorAlignment
  ) -> CGFloat {
    switch alignment {
    case .center:
      return ((anchorStart + anchorEnd) * 0.5) - bubbleLength * 0.5
    case .leading:
      return anchorStart
    case .trailing:
      return anchorEnd - bubbleLength
    }
  }

  private static func clampFrame(_ frame: CGRect, to layoutBounds: CGRect) -> CGRect {
    guard layoutBounds.width > 0, layoutBounds.height > 0 else { return frame.integral }

    var origin = frame.origin
    if frame.width <= layoutBounds.width {
      if origin.x < layoutBounds.minX {
        origin.x = layoutBounds.minX
      }
      if origin.x + frame.width > layoutBounds.maxX {
        origin.x = layoutBounds.maxX - frame.width
      }
    } else {
      origin.x = layoutBounds.minX
    }

    if frame.height <= layoutBounds.height {
      if origin.y < layoutBounds.minY {
        origin.y = layoutBounds.minY
      }
      if origin.y + frame.height > layoutBounds.maxY {
        origin.y = layoutBounds.maxY - frame.height
      }
    } else {
      origin.y = layoutBounds.minY
    }

    return CGRect(origin: origin, size: frame.size).integral
  }

  private static func overflowPenalty(frame: CGRect, layoutBounds: CGRect) -> CGFloat {
    var penalty: CGFloat = 0
    if frame.minX < layoutBounds.minX { penalty += layoutBounds.minX - frame.minX }
    if frame.maxX > layoutBounds.maxX { penalty += frame.maxX - layoutBounds.maxX }
    if frame.minY < layoutBounds.minY { penalty += layoutBounds.minY - frame.minY }
    if frame.maxY > layoutBounds.maxY { penalty += frame.maxY - layoutBounds.maxY }
    return penalty
  }
}
