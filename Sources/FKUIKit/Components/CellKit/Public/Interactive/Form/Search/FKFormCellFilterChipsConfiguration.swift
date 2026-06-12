import Foundation

/// Configuration for ``FKFormCellFilterChipsCell`` (X-30).
public struct FKFormCellFilterChipsConfiguration: Sendable, Equatable {
  public var chips: [FKChipItem]
  public var selectionMode: FKChipGroupSelectionMode
  public var selectedIDs: Set<String>
  public var isEnabled: Bool

  /// Creates a horizontal filter chips row configuration.
  public init(
    chips: [FKChipItem],
    selectionMode: FKChipGroupSelectionMode = .single,
    selectedIDs: Set<String> = [],
    isEnabled: Bool = true
  ) {
    self.chips = chips
    self.selectionMode = selectionMode
    self.selectedIDs = selectedIDs
    self.isEnabled = isEnabled
  }
}
