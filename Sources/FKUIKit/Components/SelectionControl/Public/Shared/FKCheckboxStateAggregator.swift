import Foundation

/// Derives a parent checkbox state from child checked flags (select-all / tree roots).
public enum FKCheckboxStateAggregator {
  /// Aggregates child selection into a three-state value.
  ///
  /// - Parameter checkedFlags: Per-child checked flags (`true` = checked).
  /// - Returns: `.unchecked` when all false or empty; `.checked` when all true; otherwise `.indeterminate`.
  public static func aggregate(checkedFlags: [Bool]) -> FKCheckboxState {
    guard !checkedFlags.isEmpty else { return .unchecked }
    let checkedCount = checkedFlags.filter { $0 }.count
    if checkedCount == 0 { return .unchecked }
    if checkedCount == checkedFlags.count { return .checked }
    return .indeterminate
  }
}
