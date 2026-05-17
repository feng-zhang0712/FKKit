import FKCompositeKit
import UIKit

struct FKFilterSingleListPanelExamplePanelSpec {
  let section: FKFilterSection
  let configuration: FKFilterSingleListViewController.Configuration
  let allowsMultipleSelection: Bool
  let deliversSelectionEvents: Bool
}

enum FKFilterSingleListPanelExampleCase: Int, CaseIterable {
  case baselineSingle
  case multipleSelection
  case subtitles
  case showsFooter
  case wideSeparatorInset
  case configureCellAccessory
  case heightFixed
  case heightCapped
  case attributedTitle
  case disabledRow
  case darkCellStyle
  case tallRows
  case onChangeOnlyNoSelection

  var menuTitle: String {
    switch self {
    case .baselineSingle: return "Baseline · single-select"
    case .multipleSelection: return "Multiple selection"
    case .subtitles: return "Subtitle rows"
    case .showsFooter: return "Shows footer spacer"
    case .wideSeparatorInset: return "Wide separator inset"
    case .configureCellAccessory: return "configureCell · checkmark"
    case .heightFixed: return "Height · fixed"
    case .heightCapped: return "Height · capped"
    case .attributedTitle: return "Attributed title"
    case .disabledRow: return "Disabled row"
    case .darkCellStyle: return "Dark cell chrome"
    case .tallRows: return "Taller rows"
    case .onChangeOnlyNoSelection: return "onChange only"
    }
  }

  var menuSubtitle: String {
    switch self {
    case .baselineSingle: return "Default configuration."
    case .multipleSelection: return "Section .multiple + tab allows multiple."
    case .subtitles: return "Uses .subtitle cells."
    case .showsFooter: return "showsFooter true (tableFooterView nil)."
    case .wideSeparatorInset: return "Large leading/trailing separator inset."
    case .configureCellAccessory: return "Adds trailing checkmark for selected row."
    case .heightFixed: return ".fixed(180)."
    case .heightCapped: return ".capped(maximum: 160)."
    case .attributedTitle: return "Rich title on one row."
    case .disabledRow: return "One non-interactive row."
    case .darkCellStyle: return "Grouped-like background + accent selection."
    case .tallRows: return "rowHeight 52."
    case .onChangeOnlyNoSelection: return "onSelection omitted."
    }
  }

  func makeSpec() -> FKFilterSingleListPanelExamplePanelSpec {
    switch self {
    case .baselineSingle:
      return .init(section: Self.basicSection(), configuration: .init(), allowsMultipleSelection: false, deliversSelectionEvents: true)
    case .multipleSelection:
      return .init(
        section: FKFilterSection(
          id: FKFilterID(rawValue: "sl.multi"),
          title: nil,
          selectionMode: .multiple,
          items: [
            FKFilterOptionItem(id: FKFilterID(rawValue: "m1"), title: "Alpha", isSelected: true),
            FKFilterOptionItem(id: FKFilterID(rawValue: "m2"), title: "Beta", isSelected: false),
            FKFilterOptionItem(id: FKFilterID(rawValue: "m3"), title: "Gamma", isSelected: true),
          ]
        ),
        configuration: .init(),
        allowsMultipleSelection: true,
        deliversSelectionEvents: true
      )
    case .subtitles:
      return .init(
        section: FKFilterSection(
          id: FKFilterID(rawValue: "sl.sub"),
          title: nil,
          selectionMode: .single,
          items: [
            FKFilterOptionItem(id: FKFilterID(rawValue: "s1"), title: "Newest", subtitle: "Posted recently", isSelected: true),
            FKFilterOptionItem(id: FKFilterID(rawValue: "s2"), title: "Hottest", subtitle: "Most engagement", isSelected: false),
          ]
        ),
        configuration: .init(),
        allowsMultipleSelection: false,
        deliversSelectionEvents: true
      )
    case .showsFooter:
      return .init(section: Self.basicSection(), configuration: .init(showsFooter: true), allowsMultipleSelection: false, deliversSelectionEvents: true)
    case .wideSeparatorInset:
      return .init(
        section: Self.basicSection(),
        configuration: .init(separatorInset: .init(top: 0, left: 32, bottom: 0, right: 32)),
        allowsMultipleSelection: false,
        deliversSelectionEvents: true
      )
    case .configureCellAccessory:
      return .init(
        section: Self.basicSection(),
        configuration: .init(
          configureCell: { cell, _, item, _ in
            cell.textLabel?.text = item.title
            cell.textLabel?.font = .preferredFont(forTextStyle: .subheadline)
            if !item.isEnabled {
              cell.textLabel?.textColor = .secondaryLabel
            } else if item.isSelected {
              cell.textLabel?.textColor = .systemRed
            } else {
              cell.textLabel?.textColor = .label
            }
            cell.backgroundColor = .systemBackground
            cell.selectionStyle = .default
            cell.isUserInteractionEnabled = item.isEnabled
            cell.accessoryType = item.isSelected ? .checkmark : .none
          }
        ),
        allowsMultipleSelection: false,
        deliversSelectionEvents: true
      )
    case .heightFixed:
      return .init(
        section: Self.tallSection(),
        configuration: .init(heightBehavior: .fixed(180)),
        allowsMultipleSelection: false,
        deliversSelectionEvents: true
      )
    case .heightCapped:
      return .init(
        section: Self.tallSection(),
        configuration: .init(heightBehavior: .capped(maximum: 160, minimum: 80)),
        allowsMultipleSelection: false,
        deliversSelectionEvents: true
      )
    case .attributedTitle:
      var attr = AttributedString("Featured ")
      attr.foregroundColor = .label
      var suffix = AttributedString("pick")
      suffix.foregroundColor = .systemOrange
      attr.append(suffix)
      return .init(
        section: FKFilterSection(
          id: FKFilterID(rawValue: "sl.attr"),
          title: nil,
          selectionMode: .single,
          items: [
            FKFilterOptionItem(id: FKFilterID(rawValue: "a1"), title: "Plain", attributedTitle: attr, isSelected: true),
            FKFilterOptionItem(id: FKFilterID(rawValue: "a2"), title: "Other", isSelected: false),
          ]
        ),
        configuration: .init(),
        allowsMultipleSelection: false,
        deliversSelectionEvents: true
      )
    case .disabledRow:
      return .init(
        section: FKFilterSection(
          id: FKFilterID(rawValue: "sl.dis"),
          title: nil,
          selectionMode: .single,
          items: [
            FKFilterOptionItem(id: FKFilterID(rawValue: "d1"), title: "Available", isSelected: true),
            FKFilterOptionItem(id: FKFilterID(rawValue: "d2"), title: "Unavailable", isSelected: false, isEnabled: false),
          ]
        ),
        configuration: .init(),
        allowsMultipleSelection: false,
        deliversSelectionEvents: true
      )
    case .darkCellStyle:
      let style = FKFilterListCellStyle(
        normalTextColor: .white,
        selectedTextColor: .systemYellow,
        disabledTextColor: .tertiaryLabel,
        textAlignment: .natural,
        rowBackgroundColor: .secondarySystemGroupedBackground,
        selectedRowBackgroundColor: UIColor.systemIndigo.withAlphaComponent(0.35)
      )
      return .init(section: Self.basicSection(), configuration: .init(cellStyle: style), allowsMultipleSelection: false, deliversSelectionEvents: true)
    case .tallRows:
      return .init(section: Self.basicSection(), configuration: .init(rowHeight: 52), allowsMultipleSelection: false, deliversSelectionEvents: true)
    case .onChangeOnlyNoSelection:
      return .init(section: Self.basicSection(), configuration: .init(), allowsMultipleSelection: false, deliversSelectionEvents: false)
    }
  }

  private static func basicSection() -> FKFilterSection {
    FKFilterSection(
      id: FKFilterID(rawValue: "sl.base"),
      title: nil,
      selectionMode: .single,
      items: [
        FKFilterOptionItem(id: FKFilterID(rawValue: "b1"), title: "Option A", isSelected: true),
        FKFilterOptionItem(id: FKFilterID(rawValue: "b2"), title: "Option B", isSelected: false),
        FKFilterOptionItem(id: FKFilterID(rawValue: "b3"), title: "Option C", isSelected: false),
      ]
    )
  }

  private static func tallSection() -> FKFilterSection {
    let items = (1 ... 12).map { i in
      FKFilterOptionItem(id: FKFilterID(rawValue: "t.\(i)"), title: "Sort option \(i)", isSelected: i == 1)
    }
    return FKFilterSection(id: FKFilterID(rawValue: "sl.tall"), title: nil, selectionMode: .single, items: items)
  }
}
