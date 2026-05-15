import FKCompositeKit
import UIKit

struct FKFilterChipsPanelExamplePanelSpec {
  let sections: [FKFilterSection]
  let configuration: FKFilterChipsViewController.Configuration
  let allowsMultipleSelection: Bool
  let deliversSelectionEvents: Bool
}

enum FKFilterChipsPanelExampleCase: Int, CaseIterable {
  case baselineSingleSection
  case twoSectionsSingleSelect
  case multipleSelectionTabAndSections
  case columnsTwo
  case columnsSix
  case heightFixed
  case heightCapped
  case heightScreenFraction
  case customPillStyle
  case wideContentInsets
  case tallRowHeight
  case disabledChip
  case onChangeOnlyNoSelection

  var menuTitle: String {
    switch self {
    case .baselineSingleSection: return "Baseline · single section"
    case .twoSectionsSingleSelect: return "Two sections · single-select each"
    case .multipleSelectionTabAndSections: return "Multiple · tab + sections"
    case .columnsTwo: return "Two columns"
    case .columnsSix: return "Six columns"
    case .heightFixed: return "Height · fixed"
    case .heightCapped: return "Height · capped"
    case .heightScreenFraction: return "Height · screen fraction"
    case .customPillStyle: return "Custom pill style"
    case .wideContentInsets: return "Wide content insets"
    case .tallRowHeight: return "Taller chip row height"
    case .disabledChip: return "Disabled chip"
    case .onChangeOnlyNoSelection: return "onChange only"
    }
  }

  var menuSubtitle: String {
    switch self {
    case .baselineSingleSection: return "Default configuration."
    case .twoSectionsSingleSelect: return "Two titled groups of chips."
    case .multipleSelectionTabAndSections: return "allowsMultipleSelection true; sections use .multiple."
    case .columnsTwo: return "columns = 2."
    case .columnsSix: return "columns = 6."
    case .heightFixed: return ".fixed(200)."
    case .heightCapped: return ".capped(maximum: 160)."
    case .heightScreenFraction: return ".screenFraction(0.35)."
    case .customPillStyle: return "Rounded indigo pill chrome."
    case .wideContentInsets: return "Large edge padding."
    case .tallRowHeight: return "itemRowHeight 48."
    case .disabledChip: return "One chip is not interactive."
    case .onChangeOnlyNoSelection: return "onSelection omitted."
    }
  }

  func makeSpec() -> FKFilterChipsPanelExamplePanelSpec {
    switch self {
    case .baselineSingleSection:
      return .init(sections: Self.oneSectionChips(), configuration: .init(), allowsMultipleSelection: false, deliversSelectionEvents: true)
    case .twoSectionsSingleSelect:
      return .init(sections: Self.twoSectionChips(), configuration: .init(), allowsMultipleSelection: false, deliversSelectionEvents: true)
    case .multipleSelectionTabAndSections:
      return .init(sections: Self.multiSectionChips(), configuration: .init(), allowsMultipleSelection: true, deliversSelectionEvents: true)
    case .columnsTwo:
      return .init(sections: Self.manyChips(), configuration: .init(columns: 2), allowsMultipleSelection: false, deliversSelectionEvents: true)
    case .columnsSix:
      return .init(sections: Self.manyChips(), configuration: .init(columns: 6), allowsMultipleSelection: false, deliversSelectionEvents: true)
    case .heightFixed:
      return .init(
        sections: Self.manyChips(),
        configuration: .init(heightBehavior: .fixed(200)),
        allowsMultipleSelection: false,
        deliversSelectionEvents: true
      )
    case .heightCapped:
      return .init(
        sections: Self.manyChips(),
        configuration: .init(heightBehavior: .capped(maximum: 160, minimum: 80)),
        allowsMultipleSelection: false,
        deliversSelectionEvents: true
      )
    case .heightScreenFraction:
      return .init(
        sections: Self.manyChips(),
        configuration: .init(heightBehavior: .screenFraction(0.35, minimum: 80, maximum: 360)),
        allowsMultipleSelection: false,
        deliversSelectionEvents: true
      )
    case .customPillStyle:
      let pill = FKFilterPillStyle(
        cornerRadius: 14,
        contentInsets: .init(top: 8, left: 14, bottom: 8, right: 14),
        normalTextColor: .label,
        selectedTextColor: .white,
        normalBackgroundColor: .secondarySystemFill,
        selectedBackgroundColor: .systemIndigo,
        normalBorderColor: .clear,
        selectedBorderColor: .clear
      )
      return .init(sections: Self.oneSectionChips(), configuration: .init(pillStyle: pill), allowsMultipleSelection: false, deliversSelectionEvents: true)
    case .wideContentInsets:
      return .init(
        sections: Self.oneSectionChips(),
        configuration: .init(contentInsets: .init(top: 20, left: 20, bottom: 20, right: 20)),
        allowsMultipleSelection: false,
        deliversSelectionEvents: true
      )
    case .tallRowHeight:
      return .init(
        sections: Self.oneSectionChips(),
        configuration: .init(itemRowHeight: 48),
        allowsMultipleSelection: false,
        deliversSelectionEvents: true
      )
    case .disabledChip:
      return .init(sections: Self.disabledChipSection(), configuration: .init(), allowsMultipleSelection: false, deliversSelectionEvents: true)
    case .onChangeOnlyNoSelection:
      return .init(sections: Self.oneSectionChips(), configuration: .init(), allowsMultipleSelection: false, deliversSelectionEvents: false)
    }
  }

  private static func oneSectionChips() -> [FKFilterSection] {
    [
      FKFilterSection(
        id: FKFilterID(rawValue: "chip.sec1"),
        title: nil,
        selectionMode: .single,
        items: [
          FKFilterOptionItem(id: FKFilterID(rawValue: "c1"), title: "Alpha", isSelected: true),
          FKFilterOptionItem(id: FKFilterID(rawValue: "c2"), title: "Beta", isSelected: false),
          FKFilterOptionItem(id: FKFilterID(rawValue: "c3"), title: "Gamma", isSelected: false),
        ]
      ),
    ]
  }

  private static func twoSectionChips() -> [FKFilterSection] {
    [
      FKFilterSection(
        id: FKFilterID(rawValue: "cs1"),
        title: nil,
        selectionMode: .single,
        items: [
          FKFilterOptionItem(id: FKFilterID(rawValue: "x1"), title: "Small", isSelected: true),
          FKFilterOptionItem(id: FKFilterID(rawValue: "x2"), title: "Medium", isSelected: false),
        ]
      ),
      FKFilterSection(
        id: FKFilterID(rawValue: "cs2"),
        title: nil,
        selectionMode: .single,
        items: [
          FKFilterOptionItem(id: FKFilterID(rawValue: "x3"), title: "Large", isSelected: false),
          FKFilterOptionItem(id: FKFilterID(rawValue: "x4"), title: "XL", isSelected: false),
        ]
      ),
    ]
  }

  private static func multiSectionChips() -> [FKFilterSection] {
    [
      FKFilterSection(
        id: FKFilterID(rawValue: "m1"),
        title: nil,
        selectionMode: .multiple,
        items: [
          FKFilterOptionItem(id: FKFilterID(rawValue: "m1a"), title: "A", isSelected: false),
          FKFilterOptionItem(id: FKFilterID(rawValue: "m1b"), title: "B", isSelected: true),
        ]
      ),
      FKFilterSection(
        id: FKFilterID(rawValue: "m2"),
        title: nil,
        selectionMode: .multiple,
        items: [
          FKFilterOptionItem(id: FKFilterID(rawValue: "m2a"), title: "C", isSelected: false),
        ]
      ),
    ]
  }

  private static func manyChips() -> [FKFilterSection] {
    let items = (1 ... 18).map { i in
      FKFilterOptionItem(id: FKFilterID(rawValue: "n.\(i)"), title: "Chip \(i)", isSelected: i == 1)
    }
    return [
      FKFilterSection(id: FKFilterID(rawValue: "many"), title: nil, selectionMode: .single, items: items),
    ]
  }

  private static func disabledChipSection() -> [FKFilterSection] {
    [
      FKFilterSection(
        id: FKFilterID(rawValue: "dis"),
        title: nil,
        selectionMode: .single,
        items: [
          FKFilterOptionItem(id: FKFilterID(rawValue: "d1"), title: "OK", isSelected: true),
          FKFilterOptionItem(id: FKFilterID(rawValue: "d2"), title: "Off", isSelected: false, isEnabled: false),
        ]
      ),
    ]
  }
}
