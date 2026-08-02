import Foundation
import UIKit

/// Explicit entry point for auto skeleton lifetime (``UIView/fk_showAutoSkeleton`` forwards here).
///
/// UI work runs on the main actor. The type is `@unchecked Sendable` so you may reference
/// `shared` from other isolation domains, then call ``show(on:configuration:options:animated:)`` /
/// ``hide(on:animated:completion:)`` on the main actor.
public final class FKSkeletonManager: @unchecked Sendable {
  public static let shared = FKSkeletonManager()

  private let lock = NSLock()
  private let controllerTable = NSMapTable<UIView, FKSkeletonController>(keyOptions: .weakMemory, valueOptions: .strongMemory)

  private init() {}

  @MainActor
  public func show(
    on view: UIView,
    configuration: FKSkeletonConfiguration? = nil,
    options: FKSkeletonDisplayOptions = .init(),
    animated: Bool = true
  ) {
    let controller = controller(for: view)
    controller.showSkeleton(configuration: configuration, options: options, animated: animated)
  }

  @MainActor
  public func hide(on view: UIView, animated: Bool = true, completion: (() -> Void)? = nil) {
    guard let controller = controllerTable.object(forKey: view) else {
      completion?()
      return
    }
    controller.hideSkeleton(animated: animated, completion: completion)
  }

  @MainActor
  private func controller(for view: UIView) -> FKSkeletonController {
    lock.lock()
    defer { lock.unlock() }
    if let controller = controllerTable.object(forKey: view) {
      return controller
    }
    let created = FKSkeletonController(hostView: view)
    controllerTable.setObject(created, forKey: view)
    return created
  }
}
