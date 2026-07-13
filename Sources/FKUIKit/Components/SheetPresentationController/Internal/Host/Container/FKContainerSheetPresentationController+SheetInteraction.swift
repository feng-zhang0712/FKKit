import UIKit

@MainActor
extension FKContainerSheetPresentationController {
  func sheetInteractionEnvironment(in containerView: UIView) -> FKSheetPresentationInteractionEnvironment? {
    FKSheetPresentationSheetInteractionContext.environment(
      configuration: configuration,
      containerBounds: containerView.bounds,
      presentationSafeInsets: containerSafeInsets(in: containerView)
    )
  }

  func sheetInteractionState() -> FKSheetPresentationInteractionState {
    FKSheetPresentationSheetInteractionContext.state(
      resolvedDetentHeights: resolvedDetentHeights,
      selectedDetentIndex: selectedDetentIndex,
      sheetPanBeganDetentIndex: sheetPanCoordinator.sheetPanBeganDetentIndex,
      panStartFrame: sheetPanCoordinator.panStartFrame,
      wrapperFrame: wrapperView.frame
    )
  }

  func postPresentationAccessibilityAnnouncementIfNeeded() {
    guard configuration.accessibility.announcesScreenChange else { return }
    UIAccessibility.post(notification: .screenChanged, argument: configuration.accessibility.announcement)
  }

  func makeSheetPanActions(in containerView: UIView) -> FKSheetPresentationSheetPanCoordinator.Actions {
    FKSheetPresentationSheetPanCoordinator.Actions(
      recalculateDetents: { [weak self] in self?.recalculateDetentsIfNeeded() },
      resolvedDetentHeights: { [weak self] in self?.resolvedDetentHeights ?? [] },
      selectedDetentIndex: { [weak self] in self?.selectedDetentIndex ?? 0 },
      wrapperFrame: { [weak self] in self?.wrapperView.frame ?? .zero },
      setWrapperFrame: { [weak self] frame, updateKind in
        self?.applyInteractiveFrame(frame, updateKind: updateKind)
      },
      environment: { [weak self] in
        guard let self, let containerView = self.containerView else { return nil }
        return self.sheetInteractionEnvironment(in: containerView)
      },
      interactionState: { [weak self] in self?.sheetInteractionState() ?? .init(
        resolvedDetentHeights: [],
        selectedDetentIndex: 0,
        sheetPanBeganDetentIndex: 0,
        panStartFrame: .zero,
        wrapperFrame: .zero
      ) },
      trackedScrollView: { [weak self] in self?.resolvedTrackedScrollView() },
      bypassScrollHandoff: { [weak self] recognizer, scroll in
        guard let self else { return true }
        return FKSheetPresentationSheetInteractionContext.bypassesScrollHandoff(
          recognizer: recognizer,
          wrapperView: self.wrapperView,
          contentContainerFrame: self.contentContainerView.frame,
          trackedScrollView: scroll
        )
      },
      notifyProgress: { [weak self] progress in self?.notifyProgress(progress) },
      animateToSelectedDetent: { [weak self] animated, settling in
        self?.animateToSelectedDetent(
          animated: animated,
          layoutKind: settling ? .settling : .full
        )
      },
      selectDetent: { [weak self] index, animated in self?.selectDetentIndex(index, animated: animated) },
      dismiss: { [weak self] velocityY, progress in
        self?.performInteractiveDismiss(velocityY: velocityY, completionFraction: progress)
      }
    )
  }

  func makeCenterPanActions() -> FKSheetPresentationCenterPanCoordinator.Actions {
    FKSheetPresentationCenterPanCoordinator.Actions(
      containerHeight: { [weak self] in self?.containerView?.bounds.height ?? 0 },
      captureBaseBackdropAlpha: { [weak self] in self?.captureCenterDismissBaseBackdropAlphaIfNeeded() },
      applyInteractiveDismiss: { [weak self] translationY, progress in
        self?.applyCenterInteractiveDismissTransform(translationY: translationY, progress: progress)
      },
      resetInteractiveDismiss: { [weak self] animated in
        self?.resetCenterInteractiveDismissVisuals(animated: animated)
      },
      notifyProgress: { [weak self] progress in self?.notifyProgress(progress) },
      dismiss: { [weak self] velocityY in
        guard let self else { return }
        self.commitCenterInteractiveStateForDismissal()
        self.performInteractiveDismiss(velocityY: velocityY, completionFraction: 1)
      },
      dismissProgressThreshold: { [weak self] in self?.configuration.center.dismissProgressThreshold ?? 0.5 },
      dismissVelocityThreshold: { [weak self] in self?.configuration.center.dismissVelocityThreshold ?? 900 },
      trackedScrollView: { [weak self] in self?.resolvedTrackedScrollView() },
      shouldDeferToScrollView: { [weak self] translationY in
        FKSheetPresentationSheetInteractionContext.shouldCenterPanDeferToScrollView(
          trackedScrollView: self?.resolvedTrackedScrollView(),
          translationY: translationY
        )
      }
    )
  }
}
