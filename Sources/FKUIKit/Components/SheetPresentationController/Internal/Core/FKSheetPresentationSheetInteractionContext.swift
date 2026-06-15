import UIKit

/// Shared sheet interaction environment/state builders for modal container and overlay hosts.
@MainActor
enum FKSheetPresentationSheetInteractionContext {
  static func environment(
    configuration: FKSheetPresentationConfiguration,
    containerBounds: CGRect,
    presentationSafeInsets: UIEdgeInsets
  ) -> FKSheetPresentationInteractionEnvironment? {
    guard let axis = FKSheetPresentationAxis(layout: configuration.layout) else { return nil }
    return FKSheetPresentationInteractionEnvironment(
      axis: axis,
      sheet: configuration.sheet,
      dismissBehaviorAllowsSwipe: configuration.dismissBehavior.allowsSwipe,
      safeAreaPolicy: configuration.safeAreaPolicy,
      containerBounds: containerBounds,
      containerSafeInsets: presentationSafeInsets
    )
  }

  static func state(
    resolvedDetentHeights: [CGFloat],
    selectedDetentIndex: Int,
    sheetPanBeganDetentIndex: Int,
    panStartFrame: CGRect,
    wrapperFrame: CGRect
  ) -> FKSheetPresentationInteractionState {
    FKSheetPresentationInteractionState(
      resolvedDetentHeights: resolvedDetentHeights,
      selectedDetentIndex: selectedDetentIndex,
      sheetPanBeganDetentIndex: sheetPanBeganDetentIndex,
      panStartFrame: panStartFrame,
      wrapperFrame: wrapperFrame
    )
  }

  static func bypassesScrollHandoff(
    recognizer: UIPanGestureRecognizer,
    wrapperView: UIView,
    contentContainerFrame: CGRect,
    trackedScrollView: UIScrollView?
  ) -> Bool {
    guard let trackedScrollView else { return true }
    let touchInWrapper = recognizer.location(in: wrapperView)
    let touchInScroll = recognizer.location(in: trackedScrollView)
    return FKSheetPresentationInteractionEngine.shouldBypassScrollHandoffForPan(
      touchLocationInWrapper: touchInWrapper,
      contentContainerFrame: contentContainerFrame,
      scrollView: trackedScrollView,
      touchLocationInScrollView: touchInScroll
    )
  }

  static func shouldCenterPanDismissBegin(
    recognizer: UIPanGestureRecognizer,
    wrapperView: UIView,
    contentContainerFrame: CGRect,
    trackedScrollView: UIScrollView?,
    hostedContentView: UIView?,
    verticalVelocity: CGFloat
  ) -> Bool {
    FKSheetPresentationInteractionEngine.shouldCenterPanDismissBegin(
      recognizer: recognizer,
      wrapperView: wrapperView,
      contentContainerFrame: contentContainerFrame,
      trackedScrollView: trackedScrollView,
      hostedContentView: hostedContentView,
      verticalVelocity: verticalVelocity
    )
  }

  static func shouldCenterPanDeferToScrollView(
    trackedScrollView: UIScrollView?,
    translationY: CGFloat
  ) -> Bool {
    guard let trackedScrollView else { return false }
    return FKSheetPresentationInteractionEngine.shouldCenterPanDeferToScrollView(
      scrollView: trackedScrollView,
      translationY: translationY
    )
  }
}
