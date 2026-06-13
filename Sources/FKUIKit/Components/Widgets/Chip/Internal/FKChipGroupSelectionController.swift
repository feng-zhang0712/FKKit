import Foundation

enum FKChipGroupSelectionController {
  static func toggledSelection(
    current: Set<String>,
    tappedID: String,
    mode: FKChipGroupSelectionMode,
    overflowBehavior: FKChipGroupOverflowBehavior
  ) -> (selection: Set<String>, limitReached: Bool) {
    switch mode {
    case .none:
      return (current, false)
    case .single:
      if current.contains(tappedID) {
        return ([], false)
      }
      return ([tappedID], false)
    case .multiple(let max):
      var next = current
      if next.contains(tappedID) {
        next.remove(tappedID)
        return (next, false)
      }
      if let max, next.count >= max {
        return (current, overflowBehavior == .notify)
      }
      next.insert(tappedID)
      return (next, false)
    }
  }
}
