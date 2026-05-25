import UIKit

/// Resolves the view controller used to present the sheet from ``FKActionSheetPresentationHostContext``.
@MainActor
enum FKActionSheetPresenterResolver {
  static func resolvePresenter(
    from hostContext: FKActionSheetPresentationHostContext
  ) -> UIViewController? {
    if let presenter = hostContext.presenter?.object {
      return presenter
    }
    if let window = hostContext.window?.object {
      return topMostViewController(in: window)
    }
    if let scene = hostContext.windowScene?.object {
      let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first
      if let window {
        return topMostViewController(in: window)
      }
    }
    if let keyWindow = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .flatMap({ $0.windows })
      .first(where: { $0.isKeyWindow })
    {
      return topMostViewController(in: keyWindow)
    }
    return nil
  }

  private static func topMostViewController(in window: UIWindow) -> UIViewController? {
    guard var top = window.rootViewController else { return nil }
    while let presented = top.presentedViewController {
      top = presented
    }
    return top
  }
}
