import Foundation

#if os(iOS)
import UIKit

/// Presents a lightweight pre-permission guide dialog before system prompt.
@MainActor
final class FKPermissionPrePromptPresenter {
  private let presentAlert: @MainActor (
    _ prePrompt: FKPermissionPrePrompt,
    _ presentingViewController: UIViewController,
    _ completion: @escaping (Bool) -> Void
  ) -> Void

  /// Creates a presenter that uses the default `UIAlertController` implementation.
  init() {
    presentAlert = Self.defaultPresentAlert
  }

  /// Creates a presenter with a custom alert presentation closure (for unit tests).
  init(
    presentAlert: @escaping @MainActor (
      _ prePrompt: FKPermissionPrePrompt,
      _ presentingViewController: UIViewController,
      _ completion: @escaping (Bool) -> Void
    ) -> Void
  ) {
    self.presentAlert = presentAlert
  }

  /// Presents custom pre-prompt content when provided.
  ///
  /// - Parameters:
  ///   - prePrompt: Optional custom alert content.
  ///   - presentingViewController: Optional host for the alert. When `nil`, the active key window's top controller is used.
  /// - Returns: `true` if request flow should continue, `false` if user cancelled.
  func presentIfNeeded(
    _ prePrompt: FKPermissionPrePrompt?,
    from presentingViewController: UIViewController? = nil
  ) async -> Bool {
    // Continue silently when no guide text is configured.
    guard let prePrompt else {
      return true
    }

    // Fail open when no active presentation context exists.
    guard let topViewController = presentingViewController ?? Self.findTopViewController() else {
      return true
    }

    return await withCheckedContinuation { continuation in
      presentAlert(prePrompt, topViewController) { shouldContinue in
        continuation.resume(returning: shouldContinue)
      }
    }
  }

  /// Builds the default pre-prompt alert with cancel and confirm actions.
  static func makePrePromptAlert(
    prePrompt: FKPermissionPrePrompt,
    completion: @escaping (Bool) -> Void
  ) -> UIAlertController {
    let alert = UIAlertController(title: prePrompt.title, message: prePrompt.message, preferredStyle: .alert)
    alert.addAction(
      UIAlertAction(title: prePrompt.cancelTitle, style: .cancel) { _ in
        completion(false)
      }
    )
    alert.addAction(
      UIAlertAction(title: prePrompt.confirmTitle, style: .default) { _ in
        completion(true)
      }
    )
    return alert
  }

  private static func defaultPresentAlert(
    prePrompt: FKPermissionPrePrompt,
    presentingViewController: UIViewController,
    completion: @escaping (Bool) -> Void
  ) {
    let alert = makePrePromptAlert(prePrompt: prePrompt, completion: completion)
    presentingViewController.present(alert, animated: true)
  }

  /// Finds the top-most view controller in the active foreground window scene.
  private static func findTopViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first

    let root = scene?.windows.first(where: \.isKeyWindow)?.rootViewController
      ?? scene?.windows.first?.rootViewController
    return topViewController(from: root)
  }

  /// Walks common container hierarchies to retrieve the visible controller.
  private static func topViewController(from root: UIViewController?) -> UIViewController? {
    if let navigation = root as? UINavigationController {
      return topViewController(from: navigation.visibleViewController)
    }
    if let tab = root as? UITabBarController {
      return topViewController(from: tab.selectedViewController)
    }
    if let presented = root?.presentedViewController {
      return topViewController(from: presented)
    }
    return root
  }
}

#endif
