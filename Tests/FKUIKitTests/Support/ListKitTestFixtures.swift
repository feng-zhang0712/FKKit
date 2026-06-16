import FKUIKit

/// Helpers for building ListKit snapshots in tests.
enum ListKitTestFixtures {
  static let mainSectionID: FKListSectionID = "main"

  static func textItem(id: String, title: String) -> FKListItem {
    FKListItem(
      id: FKListItemID(id),
      kind: .preset(.text(FKListTextRow(title: title)))
    )
  }

  static func switchItem(id: String, title: String, isOn: Bool) -> FKListItem {
    FKListItem(
      id: FKListItemID(id),
      kind: .preset(.switch(FKListSwitchRow(title: title, isOn: isOn, handlerID: "test-switch")))
    )
  }

  static func section(items: [FKListItem], id: FKListSectionID = mainSectionID) -> FKListSection {
    FKListSection(id: id, items: items)
  }

  static func snapshot(items: [FKListItem]) -> FKListSnapshot {
    FKListSnapshot(sections: [section(items: items)])
  }
}
