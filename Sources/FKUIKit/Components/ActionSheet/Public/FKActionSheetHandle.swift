import UIKit

/// Reference to a presented action sheet used for dismissal and live updates.
@MainActor
public final class FKActionSheetHandle {
  /// The presented action sheet view controller hosting action rows.
  public var viewController: UIViewController {
    actionSheetViewController
  }

  /// Alias for ``viewController`` retained for source compatibility.
  public var contentViewController: UIViewController {
    actionSheetViewController
  }

  let actionSheetViewController: FKActionSheetViewController

  private var configuration: FKActionSheetConfiguration
  private var pendingDismissReason: FKActionSheetDismissReason?

  init(
    viewController: FKActionSheetViewController,
    configuration: FKActionSheetConfiguration
  ) {
    self.actionSheetViewController = viewController
    self.configuration = configuration
  }

  /// Whether the sheet is currently on screen.
  public var isPresented: Bool {
    actionSheetViewController.presentingViewController != nil
  }

  /// Latest configuration used to render rows.
  public var currentConfiguration: FKActionSheetConfiguration {
    configuration
  }

  /// Dismisses the sheet when visible.
  public func dismiss(
    reason: FKActionSheetDismissReason = .programmatic,
    animated: Bool = true,
    completion: (() -> Void)? = nil
  ) {
    stageDismissReason(reason)
    actionSheetViewController.dismissSheet(animated: animated, completion: completion)
  }

  /// Replaces visible actions and header, then refreshes layout.
  ///
  /// Invalid configurations are ignored; in debug builds an `assertionFailure` is emitted.
  public func reload(configuration: FKActionSheetConfiguration) {
    guard Self.isValid(configuration) else { return }
    applyConfiguration(configuration, reloadTable: true)
  }

  weak var session: FKActionSheetSession?

  /// Updates a single action in place when the identifier matches.
  public func updateAction(_ action: FKActionSheetAction) {
    let updated = configuration.replacingAction(action)
    guard Self.isValid(updated) else { return }
    applyConfiguration(updated, reloadTable: false)
    actionSheetViewController.refreshAction(action)
  }

  /// Stores an updated configuration without reloading the table.
  func commitConfiguration(_ configuration: FKActionSheetConfiguration) {
    guard Self.isValid(configuration) else { return }
    self.configuration = configuration
    session?.updateConfiguration(configuration)
  }

  private func applyConfiguration(_ configuration: FKActionSheetConfiguration, reloadTable: Bool) {
    self.configuration = configuration
    session?.updateConfiguration(configuration)
    if reloadTable {
      actionSheetViewController.apply(configuration: configuration)
    }
  }

  private static func isValid(_ configuration: FKActionSheetConfiguration) -> Bool {
    do {
      try FKActionSheetValidator.validate(configuration)
      return true
    } catch {
      assertionFailure("FKActionSheetHandle received invalid configuration: \(error)")
      return false
    }
  }

  func stageDismissReason(_ reason: FKActionSheetDismissReason) {
    pendingDismissReason = reason
  }

  func peekPendingDismissReason() -> FKActionSheetDismissReason? {
    pendingDismissReason
  }

  func consumePendingDismissReason(default reason: FKActionSheetDismissReason) -> FKActionSheetDismissReason {
    defer { pendingDismissReason = nil }
    return pendingDismissReason ?? reason
  }
}
