import FKCompositeKit
import UIKit

struct FKFilterTwoColumnGridExamplePanelSpec {
  let model: FKFilterTwoColumnModel
  let configuration: FKFilterTwoColumnGridViewController.Configuration
  let allowsMultipleSelection: Bool
  let deliversSelectionEvents: Bool
}

enum FKFilterTwoColumnGridExampleCase: Int, CaseIterable {
  case baselineDefaults
  case sectionCollapsePlain
  case sectionCollapseInsetGroupedChrome
  case collapseChevronHidden
  case headerSelectionWithoutCollapse
  case globalSingleAcrossSections
  case withinSectionSingle
  case multipleSelectionTabAndSections
  case customLeftAndItemCells
  case narrowLeftColumn
  case heightBehaviorFixed
  case heightBehaviorCapped
  case singleColumnDense
  case fourColumnsWide
  case disabledPillItem
  case onChangeOnlyNoSelection

  var menuTitle: String {
    switch self {
    case .baselineDefaults: return "Baseline defaults"
    case .sectionCollapsePlain: return "Section collapse · plain"
    case .sectionCollapseInsetGroupedChrome: return "Section collapse · chrome tweaks"
    case .collapseChevronHidden: return "Collapse · disclosure hidden"
    case .headerSelectionWithoutCollapse: return "Selectable header only (no collapse)"
    case .globalSingleAcrossSections: return "Single · global across sections"
    case .withinSectionSingle: return "Single · within section"
    case .multipleSelectionTabAndSections: return "Multiple · tab + sections"
    case .customLeftAndItemCells: return "Custom left + item cells"
    case .narrowLeftColumn: return "Narrow left column"
    case .heightBehaviorFixed: return "Height · fixed"
    case .heightBehaviorCapped: return "Height · capped"
    case .singleColumnDense: return "One column grid"
    case .fourColumnsWide: return "Four columns"
    case .disabledPillItem: return "Disabled pill"
    case .onChangeOnlyNoSelection: return "onChange only"
    }
  }

  var menuSubtitle: String {
    switch self {
    case .baselineDefaults: return "Default grid configuration."
    case .sectionCollapsePlain: return "rightSectionHeaderBehavior .togglesSectionCollapse; mixed isCollapsed."
    case .sectionCollapseInsetGroupedChrome: return "Collapse + tighter insets and spacing."
    case .collapseChevronHidden: return "showsSectionCollapseDisclosureIndicator false."
    case .headerSelectionWithoutCollapse: return "rightSectionHeaderBehavior .selectableSectionHeader."
    case .globalSingleAcrossSections: return "singleSelectionScope .globalAcrossSections."
    case .withinSectionSingle: return "singleSelectionScope .withinSection."
    case .multipleSelectionTabAndSections: return "allowsMultipleSelection true; sections .multiple."
    case .customLeftAndItemCells: return "configureLeftCell + configureItemCell."
    case .narrowLeftColumn: return "leftColumnWidthRatio 0.22."
    case .heightBehaviorFixed: return ".fixed(280)."
    case .heightBehaviorCapped: return ".capped(maximum: 220)."
    case .singleColumnDense: return "itemColumns 1."
    case .fourColumnsWide: return "itemColumns 4."
    case .disabledPillItem: return "One disabled chip."
    case .onChangeOnlyNoSelection: return "onSelection nil."
    }
  }

  func makeSpec() -> FKFilterTwoColumnGridExamplePanelSpec {
    switch self {
    case .baselineDefaults:
      return .init(model: Self.gridCatalogModel(), configuration: .init(), allowsMultipleSelection: false, deliversSelectionEvents: true)
    case .sectionCollapsePlain:
      return .init(
        model: Self.gridCollapseModel(),
        configuration: .init(rightSectionHeaderBehavior: .togglesSectionCollapse),
        allowsMultipleSelection: false,
        deliversSelectionEvents: true
      )
    case .sectionCollapseInsetGroupedChrome:
      return .init(
        model: Self.gridCollapseModel(),
        configuration: .init(
          rightBackgroundColor: .secondarySystemGroupedBackground,
          rightContentInsets: .init(top: 8, left: 8, bottom: 8, right: 8),
          rightSectionSpacing: 10,
          rightSectionHeaderBehavior: .togglesSectionCollapse
        ),
        allowsMultipleSelection: false,
        deliversSelectionEvents: true
      )
    case .collapseChevronHidden:
      return .init(
        model: Self.gridCollapseModel(),
        configuration: .init(
          rightSectionHeaderBehavior: .togglesSectionCollapse,
          showsSectionCollapseDisclosureIndicator: false
        ),
        allowsMultipleSelection: false,
        deliversSelectionEvents: true
      )
    case .headerSelectionWithoutCollapse:
      return .init(
        model: Self.gridCatalogModel(),
        configuration: .init(rightSectionHeaderBehavior: .selectableSectionHeader),
        allowsMultipleSelection: false,
        deliversSelectionEvents: true
      )
    case .globalSingleAcrossSections:
      return .init(
        model: Self.gridScopeModel(),
        configuration: .init(singleSelectionScope: .globalAcrossSections),
        allowsMultipleSelection: false,
        deliversSelectionEvents: true
      )
    case .withinSectionSingle:
      return .init(
        model: Self.gridScopeModel(),
        configuration: .init(singleSelectionScope: .withinSection),
        allowsMultipleSelection: false,
        deliversSelectionEvents: true
      )
    case .multipleSelectionTabAndSections:
      return .init(
        model: Self.gridMultiModel(),
        configuration: .init(rightSectionHeaderBehavior: .standard),
        allowsMultipleSelection: true,
        deliversSelectionEvents: true
      )
    case .customLeftAndItemCells:
      return .init(
        model: Self.gridCatalogModel(),
        configuration: .init(
          rightSectionHeaderBehavior: .standard,
          configureLeftCell: { cell, _, cat in
            cell.textLabel?.text = "→ \(cat.title)"
            cell.textLabel?.textColor = cat.isSelected ? .systemIndigo : .label
            cell.backgroundColor = cat.isSelected ? UIColor.systemIndigo.withAlphaComponent(0.12) : .systemGray6
            cell.selectionStyle = .none
          },
          configureItemCell: { cell, _, item, _ in
            cell.contentView.layer.borderWidth = item.isSelected ? 2 : 1
            cell.contentView.layer.borderColor = (item.isSelected ? UIColor.systemGreen : UIColor.separator).cgColor
          }
        ),
        allowsMultipleSelection: false,
        deliversSelectionEvents: true
      )
    case .narrowLeftColumn:
      return .init(
        model: Self.gridCatalogModel(),
        configuration: .init(leftColumnWidthRatio: 0.22, rightSectionHeaderBehavior: .standard),
        allowsMultipleSelection: false,
        deliversSelectionEvents: true
      )
    case .heightBehaviorFixed:
      return .init(
        model: Self.gridTallModel(),
        configuration: .init(
          rightSectionHeaderBehavior: .standard,
          heightBehavior: .fixed(280)
        ),
        allowsMultipleSelection: false,
        deliversSelectionEvents: true
      )
    case .heightBehaviorCapped:
      return .init(
        model: Self.gridTallModel(),
        configuration: .init(
          rightSectionHeaderBehavior: .standard,
          heightBehavior: .capped(maximum: 220, minimum: 100)
        ),
        allowsMultipleSelection: false,
        deliversSelectionEvents: true
      )
    case .singleColumnDense:
      return .init(
        model: Self.gridCatalogModel(),
        configuration: .init(itemColumns: 1, rightSectionHeaderBehavior: .standard),
        allowsMultipleSelection: false,
        deliversSelectionEvents: true
      )
    case .fourColumnsWide:
      return .init(
        model: Self.gridManyItemsModel(),
        configuration: .init(itemColumns: 4, rightSectionHeaderBehavior: .standard),
        allowsMultipleSelection: false,
        deliversSelectionEvents: true
      )
    case .disabledPillItem:
      return .init(
        model: Self.gridDisabledModel(),
        configuration: .init(rightSectionHeaderBehavior: .standard),
        allowsMultipleSelection: false,
        deliversSelectionEvents: true
      )
    case .onChangeOnlyNoSelection:
      return .init(
        model: Self.gridCatalogModel(),
        configuration: .init(rightSectionHeaderBehavior: .standard),
        allowsMultipleSelection: false,
        deliversSelectionEvents: false
      )
    }
  }

  private static let catA = FKFilterID(rawValue: "grid.cat.a")

  private static func gridCatalogModel() -> FKFilterTwoColumnModel {
    let categories = [
      FKFilterTwoColumnModel.Category(id: catA, title: "Topics", isSelected: true),
    ]
    let sections: [FKFilterID: [FKFilterSection]] = [
      catA: [
        FKFilterSection(
          id: FKFilterID(rawValue: "g.sec1"),
          title: "Popular",
          selectionMode: .single,
          items: [
            FKFilterOptionItem(id: FKFilterID(rawValue: "g1"), title: "Swift", isSelected: true),
            FKFilterOptionItem(id: FKFilterID(rawValue: "g2"), title: "UIKit", isSelected: false),
          ]
        ),
        FKFilterSection(
          id: FKFilterID(rawValue: "g.sec2"),
          title: "More",
          selectionMode: .single,
          items: [
            FKFilterOptionItem(id: FKFilterID(rawValue: "g3"), title: "Combine", isSelected: false),
            FKFilterOptionItem(id: FKFilterID(rawValue: "g4"), title: "Concurrency", isSelected: false),
          ]
        ),
      ],
    ]
    return FKFilterTwoColumnModel(categories: categories, sectionsByCategoryID: sections)
  }

  private static func gridCollapseModel() -> FKFilterTwoColumnModel {
    let categories = [FKFilterTwoColumnModel.Category(id: catA, title: "Topics", isSelected: true)]
    let sections: [FKFilterID: [FKFilterSection]] = [
      catA: [
        FKFilterSection(
          id: FKFilterID(rawValue: "gc1"),
          title: "Open section",
          selectionMode: .single,
          items: [
            FKFilterOptionItem(id: FKFilterID(rawValue: "gc1a"), title: "A", isSelected: true),
            FKFilterOptionItem(id: FKFilterID(rawValue: "gc1b"), title: "B", isSelected: false),
          ],
          isCollapsed: false
        ),
        FKFilterSection(
          id: FKFilterID(rawValue: "gc2"),
          title: "Collapsed initially",
          selectionMode: .single,
          items: [
            FKFilterOptionItem(id: FKFilterID(rawValue: "gc2a"), title: "C", isSelected: false),
          ],
          isCollapsed: true
        ),
      ],
    ]
    return FKFilterTwoColumnModel(categories: categories, sectionsByCategoryID: sections)
  }

  private static func gridScopeModel() -> FKFilterTwoColumnModel {
    let categories = [FKFilterTwoColumnModel.Category(id: catA, title: "Scope", isSelected: true)]
    let sections: [FKFilterID: [FKFilterSection]] = [
      catA: [
        FKFilterSection(
          id: FKFilterID(rawValue: "gs1"),
          title: "Block A",
          selectionMode: .single,
          items: [
            FKFilterOptionItem(id: FKFilterID(rawValue: "gs1a"), title: "A1", isSelected: true),
            FKFilterOptionItem(id: FKFilterID(rawValue: "gs1b"), title: "A2", isSelected: false),
          ]
        ),
        FKFilterSection(
          id: FKFilterID(rawValue: "gs2"),
          title: "Block B",
          selectionMode: .single,
          items: [
            FKFilterOptionItem(id: FKFilterID(rawValue: "gs2a"), title: "B1", isSelected: false),
            FKFilterOptionItem(id: FKFilterID(rawValue: "gs2b"), title: "B2", isSelected: false),
          ]
        ),
      ],
    ]
    return FKFilterTwoColumnModel(categories: categories, sectionsByCategoryID: sections)
  }

  private static func gridMultiModel() -> FKFilterTwoColumnModel {
    let categories = [FKFilterTwoColumnModel.Category(id: catA, title: "Tags", isSelected: true)]
    let sections: [FKFilterID: [FKFilterSection]] = [
      catA: [
        FKFilterSection(
          id: FKFilterID(rawValue: "gm1"),
          title: "Set A",
          selectionMode: .multiple,
          items: [
            FKFilterOptionItem(id: FKFilterID(rawValue: "t1"), title: "One", isSelected: false),
            FKFilterOptionItem(id: FKFilterID(rawValue: "t2"), title: "Two", isSelected: true),
          ]
        ),
        FKFilterSection(
          id: FKFilterID(rawValue: "gm2"),
          title: "Set B",
          selectionMode: .multiple,
          items: [
            FKFilterOptionItem(id: FKFilterID(rawValue: "t3"), title: "Three", isSelected: false),
          ]
        ),
      ],
    ]
    return FKFilterTwoColumnModel(categories: categories, sectionsByCategoryID: sections)
  }

  private static func gridTallModel() -> FKFilterTwoColumnModel {
    let items = (1 ... 18).map { i in
      FKFilterOptionItem(id: FKFilterID(rawValue: "tall.\(i)"), title: "Item \(i)", isSelected: i == 1)
    }
    let categories = [FKFilterTwoColumnModel.Category(id: catA, title: "Tall", isSelected: true)]
    let sections: [FKFilterID: [FKFilterSection]] = [
      catA: [
        FKFilterSection(
          id: FKFilterID(rawValue: "gt"),
          title: "Many pills",
          selectionMode: .single,
          items: items
        ),
      ],
    ]
    return FKFilterTwoColumnModel(categories: categories, sectionsByCategoryID: sections)
  }

  private static func gridManyItemsModel() -> FKFilterTwoColumnModel {
    let items = (1 ... 16).map { i in
      FKFilterOptionItem(id: FKFilterID(rawValue: "m.\(i)"), title: "\(i)", isSelected: i == 1)
    }
    let categories = [FKFilterTwoColumnModel.Category(id: catA, title: "Grid", isSelected: true)]
    let sections: [FKFilterID: [FKFilterSection]] = [
      catA: [
        FKFilterSection(id: FKFilterID(rawValue: "gm"), title: "Numbers", selectionMode: .single, items: items),
      ],
    ]
    return FKFilterTwoColumnModel(categories: categories, sectionsByCategoryID: sections)
  }

  private static func gridDisabledModel() -> FKFilterTwoColumnModel {
    let categories = [FKFilterTwoColumnModel.Category(id: catA, title: "State", isSelected: true)]
    let sections: [FKFilterID: [FKFilterSection]] = [
      catA: [
        FKFilterSection(
          id: FKFilterID(rawValue: "gd"),
          title: "Options",
          selectionMode: .single,
          items: [
            FKFilterOptionItem(id: FKFilterID(rawValue: "ok"), title: "Enabled", isSelected: true),
            FKFilterOptionItem(id: FKFilterID(rawValue: "no"), title: "Disabled", isSelected: false, isEnabled: false),
          ]
        ),
      ],
    ]
    return FKFilterTwoColumnModel(categories: categories, sectionsByCategoryID: sections)
  }
}
