import UIKit

/// Safe-area fallbacks used only while resolving `.contentOnly` shell heights before the container has laid out.
@MainActor
enum FKSheetSizingSafeArea {
  static func effectiveContainerSafeAreaInsets(
    configuration: FKSheetPresentationConfiguration,
    containerInsets: UIEdgeInsets,
    window: UIWindow?
  ) -> UIEdgeInsets {
    guard configuration.preferredContentSizeReporting == .contentOnly else {
      return containerInsets
    }

    var insets = containerInsets
    switch configuration.layout {
    case .bottomSheet:
      guard configuration.safeAreaPolicy == .contentRespectsSafeArea, insets.bottom == 0 else { return insets }
      insets.bottom = resolvedWindowSafeInset(\.bottom, window: window)
    case .topSheet:
      guard configuration.safeAreaPolicy == .contentRespectsSafeArea, insets.top == 0 else { return insets }
      insets.top = resolvedWindowSafeInset(\.top, window: window)
    case .center, .anchor, .edge:
      break
    }
    return insets
  }

  private static func resolvedWindowSafeInset(
    _ keyPath: KeyPath<UIEdgeInsets, CGFloat>,
    window: UIWindow?
  ) -> CGFloat {
    if let windowValue = window?.safeAreaInsets[keyPath: keyPath], windowValue > 0 {
      return windowValue
    }
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let keyWindow = scenes.flatMap(\.windows).first(where: \.isKeyWindow)
    return keyWindow?.safeAreaInsets[keyPath: keyPath] ?? 0
  }
}
