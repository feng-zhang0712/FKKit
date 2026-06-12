import Foundation

/// Derives the active step index from explicit item states.
public enum FKFlowProgressResolver {
  /// Returns the index of the first `.current` item, else the first `.upcoming`, else the last `.completed`.
  public static func activeIndex(in items: [FKFlowStepItem]) -> Int? {
    if let current = items.firstIndex(where: { $0.state == .current }) {
      return current
    }
    if let upcoming = items.firstIndex(where: { $0.state == .upcoming }) {
      return upcoming
    }
    if let lastCompleted = items.lastIndex(where: { $0.state == .completed }) {
      return lastCompleted
    }
    return nil
  }
}
