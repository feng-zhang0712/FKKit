import Foundation

/// Selection behavior for action rows (none, single, or multiple).
public struct FKActionSheetSelectionConfiguration: Equatable, Sendable {
  /// Selection behavior applied when rows are tapped.
  public enum Mode: Equatable, Sendable {
    /// No automatic selection handling.
    case none
    /// Ensures only one row is selected within the configured scope.
    case single(scope: Scope)
    /// Allows multiple rows to be selected within the configured scope.
    case multiple(MultipleSelection)
  }

  /// Scope used by ``Mode/single(scope:)`` and ``MultipleSelection/scope``.
  public enum Scope: Equatable, Sendable {
    /// Selection applies across all sections.
    case allSections
    /// Selection applies only inside the section with this identifier.
    case section(id: UUID)
  }

  /// Limits and interaction rules for ``Mode/multiple(_:)``.
  public struct MultipleSelection: Equatable, Sendable {
    /// Section scope for multi-select rows.
    public var scope: Scope
    /// Maximum selectable rows; `nil` means unlimited.
    public var maxSelectionCount: Int?
    /// When `true`, unselected rows become non-interactive after ``maxSelectionCount`` is reached.
    public var disablesUnselectedRowsAtMax: Bool

    /// Creates multi-select limits.
    public init(
      scope: Scope = .allSections,
      maxSelectionCount: Int? = nil,
      disablesUnselectedRowsAtMax: Bool = true
    ) {
      self.scope = scope
      if let maxSelectionCount {
        self.maxSelectionCount = max(0, maxSelectionCount)
      } else {
        self.maxSelectionCount = nil
      }
      self.disablesUnselectedRowsAtMax = disablesUnselectedRowsAtMax
    }
  }

  /// Active selection mode.
  public var mode: Mode
  /// When `true`, selecting a row does not dismiss the sheet automatically.
  public var keepsSheetPresentedOnSelection: Bool
  /// Selected row for ``Mode/single(scope:)`` (restored via ``FKActionSheetConfiguration/applyingSelectionState()``).
  public var selectedActionID: UUID?
  /// Selected rows for ``Mode/multiple(_:)`` (restored via ``FKActionSheetConfiguration/applyingSelectionState()``).
  public var selectedActionIDs: Set<UUID>
  /// How selected rows are rendered.
  public var indicatorStyle: FKActionSheetSelectionIndicatorStyle
  /// When `true` and the action list scrolls, the first selected row in table order is scrolled into view on present.
  public var scrollsToSelectionOnPresent: Bool

  /// Creates selection configuration.
  public init(
    mode: Mode = .none,
    keepsSheetPresentedOnSelection: Bool = true,
    selectedActionID: UUID? = nil,
    selectedActionIDs: Set<UUID> = [],
    indicatorStyle: FKActionSheetSelectionIndicatorStyle = .check,
    scrollsToSelectionOnPresent: Bool = true
  ) {
    self.mode = mode
    self.keepsSheetPresentedOnSelection = keepsSheetPresentedOnSelection
    self.selectedActionID = selectedActionID
    self.selectedActionIDs = selectedActionIDs
    self.indicatorStyle = indicatorStyle
    self.scrollsToSelectionOnPresent = scrollsToSelectionOnPresent
  }
}
