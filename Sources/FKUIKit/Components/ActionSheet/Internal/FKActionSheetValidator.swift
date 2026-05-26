import Foundation

/// Validates action-sheet configurations before presentation or reload.
enum FKActionSheetValidator {
  static func validate(_ configuration: FKActionSheetConfiguration) throws {
    let actions = configuration.allActions
    guard !actions.isEmpty else {
      throw FKActionSheetValidationError.noActions
    }

    let cancelInSections = configuration.sections.flatMap(\.actions).filter { $0.style == .cancel }.count
    let totalCancel = cancelInSections + (configuration.cancelAction != nil ? 1 : 0)
    if totalCancel > 1 {
      throw FKActionSheetValidationError.multipleCancelActions
    }
  }

  static func validatePresentation(
    _ configuration: FKActionSheetConfiguration,
    hostContext: FKActionSheetPresentationHostContext
  ) throws {
    guard configuration.presentation.style == .popover else { return }
    guard hostContext.hasPopoverAnchor else {
      throw FKActionSheetValidationError.popoverAnchorRequired
    }
  }
}
