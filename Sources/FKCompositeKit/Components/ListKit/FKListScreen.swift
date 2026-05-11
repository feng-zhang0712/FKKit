import UIKit

/// View controllers that own one or more ``FKListPlugin`` instances as composition roots.
///
/// Implement ``listPlugins`` with every retained plugin so helpers like ``detachAllListPlugins()`` can run
/// from `viewDidDisappear` without duplicating detach logic.
///
/// Plugins keep scroll views and the host view controller as **weak** references; the screen must retain plugins.
@MainActor
public protocol FKListScreen: UIViewController {
  /// All ``FKListPlugin`` instances owned by this screen (order does not matter).
  var listPlugins: [FKListPlugin] { get }
}

extension FKListScreen {
  /// Calls ``FKListPlugin/detach()`` on every plugin in ``listPlugins``.
  public func detachAllListPlugins() {
    listPlugins.forEach { $0.detach() }
  }
}
