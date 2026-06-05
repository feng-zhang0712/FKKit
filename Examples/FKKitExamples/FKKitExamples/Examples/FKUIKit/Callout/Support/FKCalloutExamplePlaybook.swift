import UIKit
import FKUIKit

enum FKCalloutExamplePlaybook {
  static let longTooltipText =
    "Tooltip on the bottom — double line for big text that wraps inside the bubble."

  static let popoverBody =
    "Sed posuere consectetur est at lobortis. Aenean eu leo quam. Pellentesque ornare sem lacinia quam venenatis vestibulum."

  static func optionsMenu() -> FKCalloutMenu {
    FKCalloutMenu(sections: [
      FKCalloutMenuSection(items: [
        FKCalloutMenuItem(title: "Edit", symbolName: "pencil", tintColor: .systemPurple),
        FKCalloutMenuItem(title: "Duplicate", symbolName: "doc.on.doc", tintColor: .systemPurple),
      ]),
      FKCalloutMenuSection(items: [
        FKCalloutMenuItem(title: "Archive", symbolName: "archivebox", tintColor: .systemPurple),
        FKCalloutMenuItem(title: "Move", symbolName: "arrow.up.forward", tintColor: .systemPurple, isEnabled: false),
      ]),
      FKCalloutMenuSection(items: [
        FKCalloutMenuItem(title: "Delete", symbolName: "trash", tintColor: .systemPurple, isDestructive: true),
      ]),
    ])
  }

  static func selectMenu(selectedName: String) -> FKCalloutMenu {
    let names = ["Wade Cooper", "Arlene Mccoy", "Devon Webb", "Tom Cook", "Tanya Fox", "Hellen Schmidt"]
    return FKCalloutMenu(sections: [
      FKCalloutMenuSection(
        items: names.map { name in
          FKCalloutMenuItem(title: name, isSelected: name == selectedName)
        }
      ),
    ])
  }

  static func headerMenu() -> FKCalloutMenu {
    FKCalloutMenu(
      header: "eric.peters@designdrops.io",
      sections: [
        FKCalloutMenuSection(items: [
          FKCalloutMenuItem(
            id: "workspace",
            title: "DesignDrops.io",
            subtitle: "Essentials · 1 member",
            isSelected: true,
            tintColor: .systemBlue
          ),
          FKCalloutMenuItem(
            id: "personal",
            title: "Personal",
            subtitle: "Essentials · 1 member"
          ),
        ]),
        FKCalloutMenuSection(items: [
          FKCalloutMenuItem(title: "Settings", symbolName: "gearshape"),
          FKCalloutMenuItem(title: "Sign out", symbolName: "rectangle.portrait.and.arrow.right"),
        ]),
      ]
    )
  }
}
