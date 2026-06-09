import UIKit

enum FKFlowStateApplier {
  /// Applies index-driven states. Explicit `.error`, `.skipped`, and `.disabled` are preserved at every index.
  /// At `currentStepIndex`, `.current` is applied unless the item uses one of those explicit states.
  static func resolvedItems(
    from items: [FKFlowStepItem],
    currentStepIndex: Int?
  ) -> [FKFlowStepItem] {
    guard let currentStepIndex, currentStepIndex >= 0, currentStepIndex < items.count else {
      return items
    }

    return items.enumerated().map { index, item in
      switch item.state {
      case .error, .skipped, .disabled:
        return item
      default:
        break
      }

      var copy = item
      if index < currentStepIndex {
        copy.state = .completed
      } else if index > currentStepIndex {
        copy.state = .upcoming
      } else {
        copy.state = .current
      }
      return copy
    }
  }
}
