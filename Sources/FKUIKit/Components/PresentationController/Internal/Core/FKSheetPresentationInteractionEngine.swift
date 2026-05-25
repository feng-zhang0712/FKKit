import CoreGraphics
import UIKit

enum FKSheetPresentationAxis {
  case bottom
  case top

  init?(layout: FKPresentationConfiguration.Layout) {
    switch layout {
    case .bottomSheet:
      self = .bottom
    case .topSheet:
      self = .top
    default:
      return nil
    }
  }
}

struct FKSheetPresentationInteractionState {
  var resolvedDetentHeights: [CGFloat]
  var selectedDetentIndex: Int
  var sheetPanBeganDetentIndex: Int
  var panStartFrame: CGRect
  var wrapperFrame: CGRect
}

struct FKSheetPresentationInteractionEnvironment {
  let axis: FKSheetPresentationAxis
  let sheet: FKPresentationConfiguration.SheetConfiguration
  let dismissBehaviorAllowsSwipe: Bool
  let safeAreaPolicy: FKSafeAreaPolicy
  let containerBounds: CGRect
  let containerSafeInsets: UIEdgeInsets
}

enum FKSheetPresentationInteractionEngine {
  private static let defaultMinHeight: CGFloat = 240

  static func smallestDetentIndex(in resolvedHeights: [CGFloat]) -> Int {
    FKSheetDetentIndexResolver.smallestIndex(in: resolvedHeights)
  }

  static func largestDetentIndex(in resolvedHeights: [CGFloat]) -> Int {
    FKSheetDetentIndexResolver.largestIndex(in: resolvedHeights)
  }

  static func sheetMinY(environment: FKSheetPresentationInteractionEnvironment, resolvedHeights: [CGFloat]) -> CGFloat {
    let bounds = environment.containerBounds
    let safeInsets = environment.containerSafeInsets
    switch environment.axis {
    case .top:
      return environment.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.top : 0
    case .bottom:
      let maxHeight = resolvedHeights.max() ?? bounds.height * 0.5
      let extra = environment.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.bottom : 0
      return bounds.height - maxHeight - extra
    }
  }

  static func sheetMaxY(environment: FKSheetPresentationInteractionEnvironment, resolvedHeights: [CGFloat]) -> CGFloat {
    let bounds = environment.containerBounds
    let safeInsets = environment.containerSafeInsets
    switch environment.axis {
    case .top:
      return environment.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.top : 0
    case .bottom:
      let minHeight = resolvedHeights.min() ?? defaultMinHeight
      let extra = environment.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.bottom : 0
      return bounds.height - minHeight - extra
    }
  }

  static func sheetDismissPullBranchActive(
    environment: FKSheetPresentationInteractionEnvironment,
    state: FKSheetPresentationInteractionState,
    translationY: CGFloat
  ) -> Bool {
    let resolvedHeights = state.resolvedDetentHeights
    guard !resolvedHeights.isEmpty else { return false }

    let minHeight = resolvedHeights.min() ?? defaultMinHeight
    let maxHeight = resolvedHeights.max() ?? environment.containerBounds.height * 0.9
    let smallestIndex = smallestDetentIndex(in: resolvedHeights)
    let bounds = environment.containerBounds
    let safeInsets = environment.containerSafeInsets

    switch environment.axis {
    case .bottom:
      switch environment.sheet.crossDetentSwipeDismissPolicy {
      case .strictSmallestDetentAtPanStart:
        return state.sheetPanBeganDetentIndex == smallestIndex && translationY > 0
      case .systemAligned:
        if state.sheetPanBeganDetentIndex == smallestIndex, translationY > 0 { return true }
        guard translationY > 0 else { return false }
        let translationToReachMinHeight = max(0, state.panStartFrame.height - minHeight)
        let extraDismissPull = translationY - translationToReachMinHeight
        guard extraDismissPull > 0 else { return false }
        let bottomExtra = environment.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.bottom : 0
        let bottomY = bounds.height - bottomExtra
        let clampedH = min(max(state.panStartFrame.height - translationY, minHeight), maxHeight)
        let synthetic = CGRect(
          x: state.panStartFrame.minX,
          y: bottomY - clampedH,
          width: state.panStartFrame.width,
          height: clampedH
        )
        return nearestDetentIndex(environment: environment, state: state, frame: synthetic, velocityY: 0) == smallestIndex
      }
    case .top:
      let minY = environment.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.top : 0
      switch environment.sheet.crossDetentSwipeDismissPolicy {
      case .strictSmallestDetentAtPanStart:
        return state.sheetPanBeganDetentIndex == smallestIndex && translationY < 0
      case .systemAligned:
        guard translationY < 0 else { return false }
        let translationAtMin = minHeight - state.panStartFrame.height
        let extraDismissPull = translationAtMin - translationY
        guard extraDismissPull > 0 else { return false }
        let clampedH = min(max(state.panStartFrame.height + translationY, minHeight), maxHeight)
        let synthetic = CGRect(
          x: state.panStartFrame.minX,
          y: minY,
          width: state.panStartFrame.width,
          height: clampedH
        )
        return nearestDetentIndex(environment: environment, state: state, frame: synthetic, velocityY: 0) == smallestIndex
      }
    }
  }

  static func sheetDismissExtraPullWhileInBranch(
    environment: FKSheetPresentationInteractionEnvironment,
    state: FKSheetPresentationInteractionState,
    translationY: CGFloat
  ) -> CGFloat {
    let minHeight = state.resolvedDetentHeights.min() ?? defaultMinHeight
    switch environment.axis {
    case .bottom:
      let translationToReachMinHeight = max(0, state.panStartFrame.height - minHeight)
      return max(0, translationY - translationToReachMinHeight)
    case .top:
      let translationAtMin = minHeight - state.panStartFrame.height
      return max(0, translationAtMin - translationY)
    }
  }

  static func interactiveFrame(
    environment: FKSheetPresentationInteractionEnvironment,
    state: FKSheetPresentationInteractionState,
    translationY: CGFloat
  ) -> CGRect {
    switch environment.axis {
    case .bottom:
      return interactiveBottomSheetFrame(environment: environment, state: state, translationY: translationY)
    case .top:
      return interactiveTopSheetFrame(environment: environment, state: state, translationY: translationY)
    }
  }

  static func sheetDismissProgress(
    environment: FKSheetPresentationInteractionEnvironment,
    state: FKSheetPresentationInteractionState
  ) -> CGFloat {
    let bounds = environment.containerBounds
    switch environment.axis {
    case .top:
      let minY = sheetMinY(environment: environment, resolvedHeights: state.resolvedDetentHeights)
      let progress = (minY - state.wrapperFrame.minY) / max(1, bounds.height * 0.25)
      return min(max(progress, 0), 1)
    case .bottom:
      let maxY = sheetMaxY(environment: environment, resolvedHeights: state.resolvedDetentHeights)
      let progress = (maxY - state.wrapperFrame.minY) / max(1, bounds.height * 0.25)
      return min(max(progress, 0), 1)
    }
  }

  static func sheetShouldDismiss(
    environment: FKSheetPresentationInteractionEnvironment,
    state: FKSheetPresentationInteractionState,
    translationY: CGFloat,
    velocityY: CGFloat
  ) -> Bool {
    guard environment.dismissBehaviorAllowsSwipe else { return false }

    let minHeight = state.resolvedDetentHeights.min() ?? defaultMinHeight
    let threshold = environment.sheet.resolvedDismissThreshold(smallestDetentHeight: minHeight)
    let velocityThreshold = environment.sheet.dismissVelocityThreshold
    let smallestIndex = smallestDetentIndex(in: state.resolvedDetentHeights)

    switch environment.axis {
    case .bottom:
      switch environment.sheet.crossDetentSwipeDismissPolicy {
      case .strictSmallestDetentAtPanStart:
        guard state.sheetPanBeganDetentIndex == smallestIndex else { return false }
        if translationY > threshold { return true }
        if velocityY > velocityThreshold { return true }
        return false
      case .systemAligned:
        if state.sheetPanBeganDetentIndex == smallestIndex {
          if translationY > threshold { return true }
          if velocityY > velocityThreshold { return true }
          return false
        }
        guard sheetDismissPullBranchActive(environment: environment, state: state, translationY: translationY) else { return false }
        let extra = sheetDismissExtraPullWhileInBranch(environment: environment, state: state, translationY: translationY)
        if extra > threshold { return true }
        if extra > threshold * 0.5, velocityY > velocityThreshold { return true }
        return false
      }
    case .top:
      switch environment.sheet.crossDetentSwipeDismissPolicy {
      case .strictSmallestDetentAtPanStart:
        guard state.sheetPanBeganDetentIndex == smallestIndex else { return false }
        if translationY < -threshold { return true }
        if velocityY < -velocityThreshold { return true }
        return false
      case .systemAligned:
        if state.sheetPanBeganDetentIndex == smallestIndex {
          if translationY < -threshold { return true }
          if velocityY < -velocityThreshold { return true }
          return false
        }
        guard sheetDismissPullBranchActive(environment: environment, state: state, translationY: translationY) else { return false }
        let extra = sheetDismissExtraPullWhileInBranch(environment: environment, state: state, translationY: translationY)
        if extra > threshold { return true }
        if extra > threshold * 0.5, velocityY < -velocityThreshold { return true }
        return false
      }
    }
  }

  static func nearestDetentIndex(
    environment: FKSheetPresentationInteractionEnvironment,
    state: FKSheetPresentationInteractionState,
    frame: CGRect,
    velocityY: CGFloat
  ) -> Int {
    let resolvedHeights = state.resolvedDetentHeights
    guard !resolvedHeights.isEmpty else { return 0 }

    let currentHeight = currentSheetHeight(environment: environment, frame: frame)

    if abs(velocityY) > 900, resolvedHeights.count >= 2 {
      switch environment.axis {
      case .bottom:
        return velocityY < 0
          ? FKSheetDetentIndexResolver.nextTallerIndex(from: state.selectedDetentIndex, in: resolvedHeights)
          : FKSheetDetentIndexResolver.nextShorterIndex(from: state.selectedDetentIndex, in: resolvedHeights)
      case .top:
        return velocityY > 0
          ? FKSheetDetentIndexResolver.nextTallerIndex(from: state.selectedDetentIndex, in: resolvedHeights)
          : FKSheetDetentIndexResolver.nextShorterIndex(from: state.selectedDetentIndex, in: resolvedHeights)
      }
    }

    if environment.sheet.enablesMagneticSnapping {
      for (index, height) in resolvedHeights.enumerated()
        where abs(height - currentHeight) <= environment.sheet.magneticSnapThreshold {
        return index
      }
    }

    var best = 0
    var bestDistance = CGFloat.greatestFiniteMagnitude
    for (index, height) in resolvedHeights.enumerated() {
      let distance = abs(height - currentHeight)
      if distance < bestDistance {
        bestDistance = distance
        best = index
      }
    }
    return best
  }

  static func sheetOwnsDismissAxisPanFromScrollView(
    environment: FKSheetPresentationInteractionEnvironment,
    state: FKSheetPresentationInteractionState,
    translationY: CGFloat
  ) -> Bool {
    switch environment.axis {
    case .bottom:
      guard translationY > 0 else { return false }
    case .top:
      guard translationY < 0 else { return false }
    }

    let smallestIndex = smallestDetentIndex(in: state.resolvedDetentHeights)
    switch environment.sheet.crossDetentSwipeDismissPolicy {
    case .strictSmallestDetentAtPanStart:
      return state.sheetPanBeganDetentIndex == smallestIndex
    case .systemAligned:
      if state.sheetPanBeganDetentIndex == smallestIndex { return true }
      if sheetDismissPullBranchActive(environment: environment, state: state, translationY: translationY) { return true }
      return nearestDetentIndex(environment: environment, state: state, frame: state.wrapperFrame, velocityY: 0) == smallestIndex
    }
  }

  static func shouldTransferPanFromScrollView(
    environment: FKSheetPresentationInteractionEnvironment,
    state: FKSheetPresentationInteractionState,
    scrollView: UIScrollView,
    translationY: CGFloat
  ) -> Bool {
    if abs(translationY) < 0.5 { return true }

    let atTop = scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top + 0.5
    let maxOffsetY = max(
      -scrollView.adjustedContentInset.top,
      scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom
    )
    let atBottom = scrollView.contentOffset.y >= maxOffsetY - 0.5
    let canExpandToLargerDetent = state.selectedDetentIndex != largestDetentIndex(in: state.resolvedDetentHeights)

    switch environment.axis {
    case .bottom:
      if translationY < 0 {
        // Expand toward a larger detent only after the inner scroll view has reached the top.
        guard atTop else { return false }
        return canExpandToLargerDetent
      }
      if sheetOwnsDismissAxisPanFromScrollView(environment: environment, state: state, translationY: translationY) {
        return true
      }
      return atTop
    case .top:
      if translationY > 0 {
        guard atBottom else { return false }
        return canExpandToLargerDetent
      }
      if sheetOwnsDismissAxisPanFromScrollView(environment: environment, state: state, translationY: translationY) {
        return true
      }
      return atBottom
    }
  }

  /// Whether the sheet pan should begin when the touch starts on the tracked scroll view.
  ///
  /// When the scroll view is not at the handoff edge (top for bottom sheets, bottom for top sheets),
  /// vertical drags belong to the scroll view and the sheet pan must not start.
  static func shouldSheetPanBegin(
    environment: FKSheetPresentationInteractionEnvironment,
    state: FKSheetPresentationInteractionState,
    scrollView: UIScrollView,
    touchLocationInScrollView: CGPoint,
    verticalVelocity: CGFloat
  ) -> Bool {
    guard touchIsInsideScrollView(scrollView, location: touchLocationInScrollView) else { return true }

    let atTop = scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top + 0.5
    let maxOffsetY = max(
      -scrollView.adjustedContentInset.top,
      scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom
    )
    let atBottom = scrollView.contentOffset.y >= maxOffsetY - 0.5
    let canExpandToLargerDetent = state.selectedDetentIndex != largestDetentIndex(in: state.resolvedDetentHeights)

    switch environment.axis {
    case .bottom:
      guard atTop else { return false }
      if verticalVelocity < -100, !canExpandToLargerDetent { return false }
      return true
    case .top:
      guard atBottom else { return false }
      if verticalVelocity > 100, !canExpandToLargerDetent { return false }
      return true
    }
  }

  /// Whether scroll handoff should be skipped for the current pan (touch on sheet chrome / grabber band).
  static func shouldBypassScrollHandoffForPan(
    touchLocationInWrapper: CGPoint,
    contentContainerFrame: CGRect,
    scrollView: UIScrollView,
    touchLocationInScrollView: CGPoint
  ) -> Bool {
    if !contentContainerFrame.contains(touchLocationInWrapper) { return true }
    return !touchIsInsideScrollView(scrollView, location: touchLocationInScrollView)
  }

  private static func touchIsInsideScrollView(_ scrollView: UIScrollView, location: CGPoint) -> Bool {
    scrollView.bounds.contains(location)
  }

  // MARK: - Private

  private static func currentSheetHeight(
    environment: FKSheetPresentationInteractionEnvironment,
    frame: CGRect
  ) -> CGFloat {
    let bounds = environment.containerBounds
    let safeInsets = environment.containerSafeInsets
    let extra = environment.safeAreaPolicy == .containerRespectsSafeArea ? (safeInsets.top + safeInsets.bottom) : 0
    let availableHeight = bounds.height - extra

    switch environment.axis {
    case .bottom:
      let bottomExtra = environment.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.bottom : 0
      return bounds.height - frame.minY - bottomExtra
    case .top:
      return min(availableHeight, max(0, frame.height))
    }
  }

  private static func interactiveBottomSheetFrame(
    environment: FKSheetPresentationInteractionEnvironment,
    state: FKSheetPresentationInteractionState,
    translationY: CGFloat
  ) -> CGRect {
    var frame = state.panStartFrame
    let safeInsets = environment.containerSafeInsets
    let bottomExtra = environment.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.bottom : 0
    let bottomY = environment.containerBounds.height - bottomExtra
    let resolvedHeights = state.resolvedDetentHeights
    let minHeight = resolvedHeights.min() ?? defaultMinHeight
    let maxHeight = resolvedHeights.max() ?? environment.containerBounds.height * 0.9
    let dismissThreshold = environment.sheet.resolvedDismissThreshold(smallestDetentHeight: minHeight)
    let smallestIndex = smallestDetentIndex(in: resolvedHeights)

    let inDismissPullBranch = sheetDismissPullBranchActive(environment: environment, state: state, translationY: translationY)

    if inDismissPullBranch {
      switch environment.sheet.crossDetentSwipeDismissPolicy {
      case .strictSmallestDetentAtPanStart:
        frame.origin.y = state.panStartFrame.origin.y + translationY
        frame.size.height = state.panStartFrame.size.height
      case .systemAligned:
        if state.sheetPanBeganDetentIndex == smallestIndex {
          frame.origin.y = state.panStartFrame.origin.y + translationY
          frame.size.height = state.panStartFrame.size.height
        } else {
          let translationToReachMinHeight = max(0, state.panStartFrame.height - minHeight)
          let extraDismissPull = translationY - translationToReachMinHeight
          frame.size.height = minHeight
          frame.origin.y = (bottomY - minHeight) + extraDismissPull
        }
      }
    } else {
      frame.size.height = state.panStartFrame.height - translationY
      frame.size.height = min(max(frame.size.height, minHeight - dismissThreshold), maxHeight + dismissThreshold)
      frame.origin.y = bottomY - frame.size.height
    }

    let minY = sheetMinY(environment: environment, resolvedHeights: resolvedHeights)
    let maxY = sheetMaxY(environment: environment, resolvedHeights: resolvedHeights)
    if inDismissPullBranch {
      frame.origin.y = max(frame.origin.y, minY - dismissThreshold)
    } else {
      frame.origin.y = min(max(frame.origin.y, minY - dismissThreshold), maxY + dismissThreshold)
    }
    return frame
  }

  private static func interactiveTopSheetFrame(
    environment: FKSheetPresentationInteractionEnvironment,
    state: FKSheetPresentationInteractionState,
    translationY: CGFloat
  ) -> CGRect {
    var frame = state.panStartFrame
    let resolvedHeights = state.resolvedDetentHeights
    let minY = sheetMinY(environment: environment, resolvedHeights: resolvedHeights)
    let minHeight = resolvedHeights.min() ?? defaultMinHeight
    let maxHeight = resolvedHeights.max() ?? environment.containerBounds.height * 0.9
    let dismissThreshold = environment.sheet.resolvedDismissThreshold(smallestDetentHeight: minHeight)

    let inDismissPullBranch = sheetDismissPullBranchActive(environment: environment, state: state, translationY: translationY)

    if inDismissPullBranch {
      switch environment.sheet.crossDetentSwipeDismissPolicy {
      case .strictSmallestDetentAtPanStart:
        frame.origin.y = state.panStartFrame.origin.y + translationY
        frame.size.height = state.panStartFrame.size.height
      case .systemAligned:
        let translationAtMin = minHeight - state.panStartFrame.height
        let extraDismissPull = translationAtMin - translationY
        frame.size.height = minHeight
        frame.origin.y = minY - extraDismissPull
      }
    } else {
      frame.size.height = state.panStartFrame.height + translationY
      frame.size.height = min(max(frame.size.height, minHeight - dismissThreshold), maxHeight + dismissThreshold)
      frame.origin.y = minY
    }

    if inDismissPullBranch {
      frame.origin.y = min(frame.origin.y, minY)
    }
    return frame
  }
}
