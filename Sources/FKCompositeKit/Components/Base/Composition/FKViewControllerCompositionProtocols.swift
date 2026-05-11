import UIKit

// MARK: - Build phases (protocol-oriented entry points)

/// Three-phase UI construction for controllers that **do not** inherit ``FKBaseViewController``.
///
/// Conform on a `UIViewController` subclass and call ``runBuildPhases()`` from `viewDidLoad`
/// (typically after `super.viewDidLoad()`).
@MainActor
public protocol FKViewControllerBuildPhases: UIViewController {
  /// Creates and adds subviews.
  func buildInterface()
  /// Activates layout constraints for content created in ``buildInterface()``.
  func buildConstraints()
  /// Binds view models, actions, and subscriptions.
  func bindInteractions()
}

extension FKViewControllerBuildPhases {
  public func buildInterface() {}
  public func buildConstraints() {}
  public func bindInteractions() {}

  /// Runs ``buildInterface()``, ``buildConstraints()``, then ``bindInteractions()``.
  public func runBuildPhases() {
    buildInterface()
    buildConstraints()
    bindInteractions()
  }
}

// MARK: - Trait changes

/// Optional hook for dynamic type, dark mode, and other trait updates.
@MainActor
public protocol FKViewControllerTraitChangeHandling: UIViewController {
  /// Called from `traitCollectionDidChange(_:)` after `super`.
  func handleTraitCollectionChange(_ previousTraitCollection: UITraitCollection?)
}

extension FKViewControllerTraitChangeHandling {
  public func handleTraitCollectionChange(_ previousTraitCollection: UITraitCollection?) {}
}

// MARK: - Composite hosting

/// Adopters own a ``FKViewControllerComposite`` and forward lifecycle events to it.
///
/// Declare storage such as:
/// ```swift
/// final class ProfileViewController: UIViewController, FKViewControllerCompositeHosting {
///   let composite = FKViewControllerComposite()
///   // ...
/// }
/// ```
@MainActor
public protocol FKViewControllerCompositeHosting: AnyObject {
  /// Shared composition bucket (keyboard, navigation chrome, etc.).
  var composite: FKViewControllerComposite { get }
}

// MARK: - Lifecycle forwarding

/// Maps UIKit callbacks to ``FKViewControllerComposite`` so hosts avoid duplicating switch logic.
public enum FKViewControllerCompositeLifecycle {
  case viewDidLoad
  case viewWillAppear(animated: Bool)
  case viewDidAppear(animated: Bool)
  case viewWillDisappear(animated: Bool)
  case viewDidDisappear
}

// MARK: - Forwarding helper

extension FKViewControllerCompositeHosting where Self: UIViewController {
  /// Forwards `lifecycle` to ``composite`` for `self`.
  public func forwardComposite(_ lifecycle: FKViewControllerCompositeLifecycle) {
    composite.forward(lifecycle, for: self)
  }
}
