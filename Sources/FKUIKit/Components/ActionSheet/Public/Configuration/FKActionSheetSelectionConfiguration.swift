import Foundation

/// Mutual exclusion and selection behavior for single-selection action rows.
public struct FKActionSheetSelectionConfiguration: Equatable, Sendable {
  /// Selection behavior applied when rows are tapped.
  public enum Mode: Equatable, Sendable {
    /// No automatic selection handling.
    case none
    /// Ensures only one row is selected within the configured scope.
    case single(scope: Scope)
  }

  /// Scope used by ``Mode/single(scope:)``.
  public enum Scope: Equatable, Sendable {
    /// Only one selected row may be active across all sections.
    case allSections
    /// Only one selected row may be active inside the section with this identifier.
    case section(id: UUID)
  }

  /// Active selection mode.
  public var mode: Mode
  /// When `true`, tapping a row toggles `isSelected` without dismissing the sheet.
  public var keepsSheetPresentedOnSelection: Bool
  /// Action identifier to mark selected when the sheet is presented (for example, the last user choice).
  public var selectedActionID: UUID?
  /// How selected rows are rendered.
  public var indicatorStyle: FKActionSheetSelectionIndicatorStyle

  /// Creates selection configuration.
  public init(
    mode: Mode = .none,
    keepsSheetPresentedOnSelection: Bool = true,
    selectedActionID: UUID? = nil,
    indicatorStyle: FKActionSheetSelectionIndicatorStyle = .check
  ) {
    self.mode = mode
    self.keepsSheetPresentedOnSelection = keepsSheetPresentedOnSelection
    self.selectedActionID = selectedActionID
    self.indicatorStyle = indicatorStyle
  }
}
