import UIKit

@MainActor
extension FKContainerSheetPresentationController {
  func sheetInteractionEnvironment(in containerView: UIView) -> FKSheetPresentationInteractionEnvironment? {
    guard let axis = FKSheetPresentationAxis(layout: configuration.layout) else { return nil }
    return FKSheetPresentationInteractionEnvironment(
      axis: axis,
      sheet: configuration.sheet,
      dismissBehaviorAllowsSwipe: configuration.dismissBehavior.allowsSwipe,
      safeAreaPolicy: configuration.safeAreaPolicy,
      containerBounds: containerView.bounds,
      containerSafeInsets: containerSafeInsets(in: containerView)
    )
  }

  func sheetInteractionState() -> FKSheetPresentationInteractionState {
    FKSheetPresentationInteractionState(
      resolvedDetentHeights: resolvedDetentHeights,
      selectedDetentIndex: selectedDetentIndex,
      sheetPanBeganDetentIndex: sheetPanBeganDetentIndex,
      panStartFrame: panStartFrame,
      wrapperFrame: wrapperView.frame
    )
  }

  func postPresentationAccessibilityAnnouncementIfNeeded() {
    guard configuration.accessibility.announcesScreenChange else { return }
    UIAccessibility.post(notification: .screenChanged, argument: configuration.accessibility.announcement)
  }
}
