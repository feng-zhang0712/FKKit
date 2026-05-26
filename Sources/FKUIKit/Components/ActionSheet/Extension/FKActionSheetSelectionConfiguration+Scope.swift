import Foundation

extension FKActionSheetSelectionConfiguration.Scope {
  /// Whether single-selection state should apply to the section with this identifier.
  func contains(sectionID: UUID) -> Bool {
    switch self {
    case .allSections:
      return true
    case .section(let id):
      return sectionID == id
    }
  }
}
