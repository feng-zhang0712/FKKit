import UIKit
import FKUIKit

/// Loading / failure helpers for FKActionSheet deferred-content demos.
enum FKActionSheetExampleLoadingSupport {
  static func standardLoadingContent(
    title: String = "Loading options",
    message: String = "Fetching share targets from the server…"
  ) -> FKActionSheetStandardLoadingContent {
    FKActionSheetStandardLoadingContent(title: title, message: message)
  }

  static func standardLoadingConfiguration(
    preferredPanelHeight: CGFloat = 196,
    title: String = "Loading options",
    message: String = "Fetching share targets from the server…"
  ) -> FKActionSheetLoadingConfiguration {
    FKActionSheetLoadingConfiguration(
      content: .standard(standardLoadingContent(title: title, message: message)),
      preferredPanelHeight: preferredPanelHeight
    )
  }

  /// Centered failure UI using ``FKEmptyStateView`` inside custom loading content (sheet stays in loading mode).
  static func failureLoadingConfiguration(
    preferredPanelHeight: CGFloat = 196,
    title: String = "Couldn't load options",
    message: String = "Check your connection and try again.",
    retryTitle: String = "Retry",
    onRetry: @escaping @MainActor () -> Void
  ) -> FKActionSheetLoadingConfiguration {
    let custom = FKActionSheetCustomLoadingContent(
      accessibilityLabel: title,
      fillsAvailableArea: true,
      provider: .init { context in
        makeFailureEmptyStateHost(
          context: context,
          title: title,
          message: message,
          retryTitle: retryTitle,
          onRetry: onRetry
        )
      }
    )
    return FKActionSheetLoadingConfiguration(
      content: .custom(custom),
      preferredPanelHeight: preferredPanelHeight
    )
  }

  private static func makeFailureEmptyStateHost(
    context: FKActionSheetLoadingBuildContext,
    title: String,
    message: String,
    retryTitle: String,
    onRetry: @escaping @MainActor () -> Void
  ) -> UIView {
    let host = UIView()
    host.translatesAutoresizingMaskIntoConstraints = false

    var configuration = FKEmptyStateConfiguration(phase: .error, type: .error)
    configuration.title = title
    configuration.description = message
    configuration.image = UIImage(systemName: "exclamationmark.triangle")
    configuration.imageSize = CGSize(width: 40, height: 40)
    configuration.buttonStyle.title = retryTitle
    configuration.blockingOverlayAlpha = 0
    configuration.announcesStateChanges = false
    configuration.contentAlignment = .center
    configuration.titleColor = context.appearance.headerTitleColor
    configuration.descriptionColor = context.appearance.headerMessageColor

    // FKEmptyStateView starts hidden (alpha = 0); fk_applyEmptyState reveals it like other demos.
    host.fk_applyEmptyState(configuration, animated: false) { action in
      guard action.id == "primary" else { return }
      onRetry()
    }
    return host
  }
}
