import UIKit

/// Applies UIKit presentation attributes for each ``FKActionSheetPresentationStyle``.
@MainActor
enum FKActionSheetPresentationConfigurator {
  static func configure(
    sheet: FKActionSheetViewController,
    hostContext: FKActionSheetPresentationHostContext,
    presenter: UIViewController
  ) throws {
    switch sheet.presentationConfiguration.style {
    case .bottom, .centered:
      break
    case .popover:
      try configurePopover(sheet: sheet, hostContext: hostContext, presenter: presenter)
    }
  }

  private static func configurePopover(
    sheet: FKActionSheetViewController,
    hostContext: FKActionSheetPresentationHostContext,
    presenter: UIViewController
  ) throws {
    guard hostContext.hasPopoverAnchor else {
      throw FKActionSheetValidationError.popoverAnchorRequired
    }

    sheet.modalPresentationStyle = .popover

    guard let popover = sheet.popoverPresentationController else { return }

    if let barButtonItem = hostContext.popoverBarButtonItem?.object {
      popover.barButtonItem = barButtonItem
    } else if let sourceView = hostContext.popoverSourceView?.object {
      popover.sourceView = sourceView
      popover.sourceRect = hostContext.resolvedPopoverSourceRect
    }

    popover.permittedArrowDirections = hostContext.permittedPopoverArrowDirections

    if let delegate = presenter as? UIPopoverPresentationControllerDelegate {
      popover.delegate = delegate
    }
  }
}
