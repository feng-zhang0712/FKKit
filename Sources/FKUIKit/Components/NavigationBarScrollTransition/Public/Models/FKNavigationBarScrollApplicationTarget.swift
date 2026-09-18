import Foundation

/// Where automatic navigation-bar appearance writes are applied.
public enum FKNavigationBarScrollApplicationTarget: Sendable, Equatable {
  /// Write appearances on the bound view controller’s ``UINavigationItem`` (preferred for push stacks).
  case navigationItem

  /// Write appearances on ``UINavigationController/navigationBar``.
  case navigationBar

  /// Write item appearances first, then the shared bar.
  case both
}
