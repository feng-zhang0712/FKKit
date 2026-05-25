import Foundation

extension FKActionSheetSelectionIndicatorStyle {
  var usesCheck: Bool {
    switch self {
    case .check, .checkAndHighlightedTitle:
      return true
    case .highlightedTitle, .radio, .radioAndHighlightedTitle:
      return false
    }
  }

  var usesRadio: Bool {
    switch self {
    case .radio, .radioAndHighlightedTitle:
      return true
    case .highlightedTitle, .check, .checkAndHighlightedTitle:
      return false
    }
  }

  var usesSelectionAccessory: Bool {
    usesCheck || usesRadio
  }

  var usesHighlightedTitle: Bool {
    switch self {
    case .highlightedTitle, .checkAndHighlightedTitle, .radioAndHighlightedTitle:
      return true
    case .check, .radio:
      return false
    }
  }
}
