import UIKit

/// Reference to a presented action sheet used for dismissal and live updates.
@MainActor
public final class FKActionSheetHandle {
  /// Underlying presentation controller.
  public private(set) var presentationController: FKPresentationController
  /// Content controller hosting action rows.
  public var contentViewController: UIViewController {
    contentController
  }

  let contentController: FKActionSheetContentViewController

  private var configuration: FKActionSheetConfiguration
  private var pendingDismissReason: FKActionSheetDismissReason?

  init(
    presentationController: FKPresentationController,
    contentController: FKActionSheetContentViewController,
    configuration: FKActionSheetConfiguration
  ) {
    self.presentationController = presentationController
    self.contentController = contentController
    self.configuration = configuration
  }

  /// Whether the sheet is currently on screen.
  public var isPresented: Bool {
    presentationController.isPresented
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
    presentationController.dismiss(animated: animated, completion: completion)
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
    var updated = configuration
    updated.sections = updated.sections.map { section in
      var copy = section
      copy.actions = section.actions.map { $0.id == action.id ? action : $0 }
      return copy
    }
    if updated.cancelAction?.id == action.id {
      updated.cancelAction = action
    }
    guard Self.isValid(updated) else { return }
    applyConfiguration(updated, reloadTable: false)
    contentController.refreshAction(action)
    presentationController.updateLayout(animated: false)
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
      contentController.apply(configuration: configuration)
    }
    presentationController.updateLayout(animated: false)
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

  func replacePresentationController(_ controller: FKPresentationController) {
    presentationController = controller
  }
}
