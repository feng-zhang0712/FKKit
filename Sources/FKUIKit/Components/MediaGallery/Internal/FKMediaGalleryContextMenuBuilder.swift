import UIKit

@MainActor
enum FKMediaGalleryContextMenuBuilder {
  struct ActionItem {
    var title: String
    var handler: () -> Void
  }

  static func makeActions(
    for item: FKMediaGalleryItem,
    configuration: FKMediaGalleryContextMenuConfiguration,
    handlers: Handlers
  ) -> [ActionItem] {
    var actions: [ActionItem] = []
    if configuration.showsSaveToPhotosAction {
      actions.append(ActionItem(title: FKMediaGalleryI18n.saveTitle, handler: handlers.onSave))
    }
    if configuration.showsShareAction {
      actions.append(ActionItem(title: FKMediaGalleryI18n.shareTitle, handler: handlers.onShare))
    }
    if configuration.showsCopyLinkAction, item.shareURL != nil {
      actions.append(
        ActionItem(title: FKMediaGalleryI18n.copyLinkTitle) {
          if let shareURL = item.shareURL {
            UIPasteboard.general.url = shareURL
            FKToast.show(FKMediaGalleryI18n.linkCopiedMessage)
          }
        }
      )
    }
    if configuration.showsEditAction {
      actions.append(ActionItem(title: FKMediaGalleryI18n.editTitle, handler: handlers.onEdit))
    }
    return actions
  }

  static func makeMenu(
    for item: FKMediaGalleryItem,
    configuration: FKMediaGalleryContextMenuConfiguration,
    handlers: Handlers
  ) -> UIMenu {
    let actions = makeActions(for: item, configuration: configuration, handlers: handlers)
    let menuActions = actions.map { action in
      UIAction(title: action.title) { _ in action.handler() }
    }
    return UIMenu(children: menuActions)
  }

  struct Handlers {
    var onSave: () -> Void
    var onShare: () -> Void
    var onEdit: () -> Void
  }
}
