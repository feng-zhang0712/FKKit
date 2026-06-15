import UIKit

/// Builds ``UISwipeActionsConfiguration`` values for ListKit table and collection lists.
@MainActor
enum FKListSwipeActionsBuilder {
  enum Edge {
    case leading
    case trailing
  }

  static func configuration(
    for item: FKListItem,
    itemID: FKListItemID,
    edge: Edge,
    handlerRegistry: FKListSwipeActionHandlerRegistry
  ) -> UISwipeActionsConfiguration? {
    guard let swipeActions = item.swipeActions else { return nil }
    let actions = edge == .trailing ? swipeActions.trailing : swipeActions.leading
    guard !actions.isEmpty else { return nil }
    let contextual = actions.map { action -> UIContextualAction in
      let uiAction = UIContextualAction(style: mapStyle(action.style), title: action.title) { _, _, completion in
        handlerRegistry.handler(for: action.id)?(itemID)
        completion(true)
      }
      uiAction.accessibilityLabel = action.title
      if let icon = action.icon {
        uiAction.image = UIImage(systemName: icon.symbolName)
      }
      return uiAction
    }
    let config = UISwipeActionsConfiguration(actions: contextual)
    config.performsFirstActionWithFullSwipe = swipeActions.permitsFullSwipe
    return config
  }

  private static func mapStyle(_ style: FKListSwipeActionStyle) -> UIContextualAction.Style {
    switch style {
    case .normal: return .normal
    case .destructive: return .destructive
    case .cancel: return .normal
    }
  }
}
