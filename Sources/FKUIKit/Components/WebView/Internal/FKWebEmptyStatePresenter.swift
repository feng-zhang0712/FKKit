import UIKit

@MainActor
final class FKWebEmptyStatePresenter {
  enum OverlayKind: Equatable {
    case none
    case offline
    case error(FKWebViewError)
  }

  private weak var hostView: UIView?
  private var currentKind: OverlayKind = .none
  private var lastFailedURL: URL?

  func attach(hostView: UIView) {
    self.hostView = hostView
  }

  func showOffline(
    configuration: FKWebErrorConfiguration,
    onRetry: @escaping () -> Void
  ) {
    guard configuration.showsEmptyStateOverlay, let hostView else { return }
    currentKind = .offline

    var emptyConfiguration = FKEmptyStateConfiguration.scenario(.noNetwork)
    emptyConfiguration.phase = .error
    emptyConfiguration.type = .offline
    emptyConfiguration.actions = retryActions(configuration: configuration, url: nil, onRetry: onRetry)

    hostView.fk_applyEmptyState(emptyConfiguration) { action in
      if action.id == "retry" {
        onRetry()
      } else if action.id == "open_in_safari" {
        // Offline overlay has no Safari action.
      }
    }
  }

  func showError(
    _ error: FKWebViewError,
    url: URL?,
    configuration: FKWebErrorConfiguration,
    onRetry: @escaping () -> Void,
    onOpenInSafari: @escaping (URL) -> Void
  ) {
    guard configuration.showsEmptyStateOverlay, let hostView else { return }
    currentKind = .error(error)
    lastFailedURL = url

    var emptyConfiguration = FKEmptyStateConfiguration.scenario(.loadFailed)
    emptyConfiguration.content.description = localizedDescription(for: error)
    emptyConfiguration.actions = retryActions(
      configuration: configuration,
      url: url,
      onRetry: onRetry,
      onOpenInSafari: onOpenInSafari
    )

    hostView.fk_applyEmptyState(emptyConfiguration) { [weak self] action in
      if action.id == "retry" {
        onRetry()
      } else if action.id == "open_in_safari", let openURL = url ?? self?.lastFailedURL {
        onOpenInSafari(openURL)
      }
    }
  }

  func hide() {
    currentKind = .none
    hostView?.fk_hideEmptyState(animated: true)
  }

  private func retryActions(
    configuration: FKWebErrorConfiguration,
    url: URL?,
    onRetry: @escaping () -> Void,
    onOpenInSafari: ((URL) -> Void)? = nil
  ) -> FKEmptyStateActionSet {
    var actions = FKEmptyStateActionSet.primary(
      FKUIKitI18n.string("fkuikit.webview.action.retry"),
      id: "retry"
    )

    if configuration.showsOpenInSafariAction,
      let url,
      let scheme = url.scheme?.lowercased(),
      scheme == "http" || scheme == "https" {
      actions.secondary = FKEmptyStateAction(
        id: "open_in_safari",
        title: FKUIKitI18n.string("fkuikit.webview.action.open_in_safari"),
        kind: .secondary
      )
    }

    return actions
  }

  private func localizedDescription(for error: FKWebViewError) -> String {
    switch error {
    case .notConnectedToInternet:
      return FKUIKitI18n.string("fkuikit.webview.error.not_connected")
    case .timedOut:
      return FKUIKitI18n.string("fkuikit.webview.error.timed_out")
    case .secureConnectionFailed:
      return FKUIKitI18n.string("fkuikit.webview.error.secure_connection")
    case .serverError(let statusCode):
      return FKUIKitI18n.format("fkuikit.webview.error.server_error", statusCode)
    case .cancelled:
      return FKUIKitI18n.string("fkuikit.webview.error.cancelled")
    case .unreachableHost:
      return FKUIKitI18n.string("fkuikit.webview.error.unreachable_host")
    case .hostDenied:
      return FKUIKitI18n.string("fkuikit.webview.error.host_denied")
    case .custom(let message):
      return message
    case .webKit:
      return FKUIKitI18n.string("fkuikit.webview.error.generic")
    }
  }
}
