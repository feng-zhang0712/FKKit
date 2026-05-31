import Foundation

/// Read-only selection snapshot exposed by ``FKTabBar`` for host coordination.
public struct FKTabBarSelectionSnapshot: Equatable, Sendable {
  /// Currently selected visible index.
  public var selectedIndex: Int
  /// Previously selected visible index, if any.
  public var previousIndex: Int?
  /// Current switching phase.
  public var phase: FKTabBarSwitchPhase
  /// Stable identifier of the selected visible item; `nil` when the strip is empty.
  public var selectedItemID: String?

  public init(
    selectedIndex: Int,
    previousIndex: Int? = nil,
    phase: FKTabBarSwitchPhase = .idle,
    selectedItemID: String? = nil
  ) {
    self.selectedIndex = selectedIndex
    self.previousIndex = previousIndex
    self.phase = phase
    self.selectedItemID = selectedItemID
  }
}
