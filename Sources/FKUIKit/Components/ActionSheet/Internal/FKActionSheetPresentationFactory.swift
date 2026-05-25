import UIKit

@MainActor
enum FKActionSheetPresentationFactory {
  static func makePresentationConfiguration(
    sheetPresentation: FKActionSheetPresentationConfiguration,
    transform: FKActionSheetPresentationConfiguration.ConfigurationTransform? = nil
  ) -> FKPresentationConfiguration {
    var configuration = makeBottomSheetConfiguration(sheetPresentation: sheetPresentation)
    configuration = transform?(configuration) ?? configuration
    if sheetPresentation.respectsReduceMotion, UIAccessibility.isReduceMotionEnabled {
      configuration.animation.preset = .fade
      configuration.animation.duration = 0.2
    }
    return configuration
  }

  private static func makeBottomSheetConfiguration(
    sheetPresentation: FKActionSheetPresentationConfiguration
  ) -> FKPresentationConfiguration {
    var configuration = FKPresentationConfiguration()
    configuration.layout = .bottomSheet(
      .init(
        detents: [.fitContent],
        initialSelectedDetentIndex: 0,
        maximumFitContentHeightFraction: sheetPresentation.maximumFitContentHeightFraction,
        prefersGrabberVisible: false,
        minimumContentHeight: nil,
        // Content-height caps (including `maximumPanelHeight`) are applied in
        // `FKActionSheetContentViewController` so `preferredContentSize` can include bottom safe area.
        maximumContentHeight: nil
      )
    )
    // Shell and hosted content share the same height; the table footer reserves the home-indicator area.
    configuration.safeAreaPolicy = .shellExtendsToScreenBottomEdge
    configuration.cornerRadius = sheetPresentation.cornerRadius
    configuration.shadow = sheetPresentation.containerShadow
    configuration.backdropStyle = .dim(alpha: sheetPresentation.backdropAlpha)
    configuration.dismissBehavior = .init(
      allowsTapOutside: sheetPresentation.allowsTapOutsideDismiss,
      allowsSwipe: sheetPresentation.allowsSwipeDismiss,
      allowsBackdropTap: sheetPresentation.allowsTapOutsideDismiss
    )
    configuration.keyboardAvoidance.isEnabled = false
    configuration.contentInsets = .zero
    configuration.preferredContentSizePolicy = .strict
    configuration.sheet.scrollTrackingStrategy = .disabled
    return configuration
  }
}
