import Foundation

/// Validates action-sheet configurations before presentation or reload.
enum FKActionSheetValidator {
  static func validate(_ configuration: FKActionSheetConfiguration) throws {
    let actions = configuration.allActions
    guard !actions.isEmpty else {
      throw FKActionSheetValidationError.noActions
    }

    let cancelInSections = configuration.sections.flatMap(\.actions).filter { $0.style == .cancel }.count
    let totalCancel = cancelInSections + (configuration.cancelAction != nil ? 1 : 0)
    if totalCancel > 1 {
      throw FKActionSheetValidationError.multipleCancelActions
    }

    try validateSelection(configuration)
  }

  private static func validateSelection(_ configuration: FKActionSheetConfiguration) throws {
    switch configuration.selection.mode {
    case .none:
      return
    case .single(let scope):
      try validateSelectedActionID(
        configuration.selection.selectedActionID,
        scope: scope,
        sections: configuration.sections
      )
    case .multiple(let multiple):
      let scopedActionIDs = Set(
        configuration.sections.flatMap { section -> [UUID] in
          guard multiple.scope.contains(sectionID: section.id) else { return [] }
          return section.actions.map(\.id)
        }
      )

      let unknownIDs = configuration.selection.selectedActionIDs.subtracting(scopedActionIDs)
      if !unknownIDs.isEmpty {
        throw FKActionSheetValidationError.unknownSelectedActionIDs
      }

      if let maxSelectionCount = multiple.maxSelectionCount,
         configuration.selection.selectedActionIDs.count > maxSelectionCount {
        throw FKActionSheetValidationError.selectedCountExceedsMaximum
      }
    }
  }

  private static func validateSelectedActionID(
    _ selectedActionID: UUID?,
    scope: FKActionSheetSelectionConfiguration.Scope,
    sections: [FKActionSheetSection]
  ) throws {
    guard let selectedActionID else { return }

    let scopedActionIDs = Set(
      sections.flatMap { section -> [UUID] in
        guard scope.contains(sectionID: section.id) else { return [] }
        return section.actions.map(\.id)
      }
    )

    if !scopedActionIDs.contains(selectedActionID) {
      throw FKActionSheetValidationError.unknownSelectedActionIDs
    }
  }
}
