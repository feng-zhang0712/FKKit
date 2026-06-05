import UIKit
import FKCoreKit

final class FKTabBarExamplesHubViewController: UITableViewController {
  // MARK: - Navigation shell (TabBar)
  //
  // This hub is intentionally a lightweight navigation shell for open-source users.
  // Each destination page demonstrates one capability area and how to integrate FKTabBar as a UIView.
  //
  // Important boundaries:
  // - FKTabBar does NOT manage controllers, navigation, or paging containers.
  // - Example pages may simulate "paging progress" via slider, but FKTabBar only renders UI and interpolation.
  private struct SectionModel {
    let title: String
    let rows: [RowModel]
  }

  private struct RowModel {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private let sections: [SectionModel] = [
    SectionModel(
      title: FKExamplesI18n.string("examples.scenario.examples_fkuikit_tabbar_scenarios_basics_fktabba.basic.aa2c96dacf"),
      rows: [
        RowModel(
          title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.0.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.0.subtitle"),
          make: { FKTabBarBasicPlaygroundExampleViewController() }
        ),
        RowModel(
          title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.1.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.1.subtitle"),
          make: { FKTabBarContentTypesExampleViewController() }
        ),
        RowModel(
          title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.2.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.2.subtitle"),
          make: { FKTabBarFilterStripExampleViewController() }
        ),
        RowModel(
          title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.3.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.3.subtitle"),
          make: { FKTabBarPresetsExampleViewController() }
        ),
      ]
    ),
    SectionModel(
      title: "Layout & insets",
      rows: [
        RowModel(
          title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.4.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.4.subtitle"),
          make: { FKTabBarItemInsetsExampleViewController() }
        ),
        RowModel(
          title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.5.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.5.subtitle"),
          make: { FKTabBarContentAlignmentExampleViewController() }
        ),
        RowModel(
          title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.6.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.6.subtitle"),
          make: { FKTabBarInsetsSpacingExampleViewController() }
        ),
        RowModel(
          title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.7.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.7.subtitle"),
          make: { FKTabBarScrollEdgeFadeExampleViewController() }
        ),
        RowModel(
          title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.8.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.8.subtitle"),
          make: { FKTabBarCustomSpacingExampleViewController() }
        ),
        RowModel(
          title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.9.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.9.subtitle"),
          make: { FKTabBarGlobalSubtitleExampleViewController() }
        ),
      ]
    ),
    SectionModel(
      title: "Scrollable",
      rows: [
        RowModel(
          title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.10.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.10.subtitle"),
          make: { FKTabBarScrollableManyTabsExampleViewController() }
        ),
        RowModel(
          title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.11.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.11.subtitle"),
          make: { FKTabBarLongTitleStrategyExampleViewController() }
        ),
        RowModel(
          title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.12.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.12.subtitle"),
          make: { FKTabBarScrollAndWidthStrategyExampleViewController() }
        ),
      ]
    ),
    SectionModel(
      title: "Indicator",
      rows: [
        RowModel(
          title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.13.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.13.subtitle"),
          make: { FKTabBarIndicatorAnimationExampleViewController() }
        ),
        RowModel(
          title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.14.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.14.subtitle"),
          make: { FKTabBarIndicatorAdvancedExampleViewController() }
        ),
        RowModel(
          title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.15.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.15.subtitle"),
          make: { FKTabBarPagingProgressExampleViewController() }
        ),
        RowModel(
          title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.16.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.16.subtitle"),
          make: { FKTabBarReduceMotionExampleViewController() }
        ),
      ]
    ),
    SectionModel(
      title: FKExamplesI18n.string("examples.menu.item.badge.6d12c8adbe"),
      rows: [
        RowModel(
          title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.17.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.17.subtitle"),
          make: { FKTabBarBadgeAnchorAndLandscapeExampleViewController() }
        ),
        RowModel(
          title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.18.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.18.subtitle"),
          make: { FKTabBarBadgeUpdatesExampleViewController() }
        ),
      ]
    ),
    SectionModel(
      title: FKExamplesI18n.string("examples.scenario.examples_fkuikit_tabbar_scenarios_replaceuitabba.replace_uitabbar.b18a70f7ff"),
      rows: [
        RowModel(
          title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.19.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.19.subtitle"),
          make: { FKTabBarReplaceUITabBarExampleViewController() }
        ),
      ]
    ),
    SectionModel(
      title: "RTL / Dynamic Type / Accessibility",
      rows: [
        RowModel(
          title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.20.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.20.subtitle"),
          make: { FKTabBarRTLExampleViewController() }
        ),
        RowModel(
          title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.21.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.21.subtitle"),
          make: { FKTabBarDynamicTypeExampleViewController() }
        ),
        RowModel(
          title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.22.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.22.subtitle"),
          make: { FKTabBarAccessibilityExampleViewController() }
        ),
        RowModel(
          title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.23.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.23.subtitle"),
          make: { FKTabBarI18nA11yExampleViewController() }
        ),
      ]
    ),
    SectionModel(
      title: FKExamplesI18n.string("examples.hub.fki18nexampleshubviewcontroller.6.title"),
      rows: {
        var rows = [
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.24.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.24.subtitle"),
            make: { FKTabBarCustomizationHooksExampleViewController() }
          ),
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.25.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.25.subtitle"),
            make: { FKTabBarBatchUpdatesExampleViewController() }
          ),
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.26.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.26.subtitle"),
            make: { FKTabBarStableIDExampleViewController() }
          ),
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.27.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.27.subtitle"),
            make: { FKTabBarLongPressExampleViewController() }
          ),
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.28.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.28.subtitle"),
            make: { FKTabBarCustomBadgeExampleViewController() }
          ),
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.29.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.29.subtitle"),
            make: { FKTabBarDataSourceExampleViewController() }
          ),
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.30.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.30.subtitle"),
            make: { FKTabBarNonScrollableOverflowExampleViewController() }
          ),
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.31.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.31.subtitle"),
            make: { FKTabBarEmptyStateExampleViewController() }
          ),
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.32.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.32.subtitle"),
            make: { FKTabBarSelectionObservabilityExampleViewController() }
          ),
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.33.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.33.subtitle"),
            make: { FKTabBarVisibleItemButtonExampleViewController() }
          ),
        ]
        #if canImport(SwiftUI)
        rows.append(
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.34.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.34.subtitle"),
            make: { FKTabBarSwiftUIExampleViewController() }
          )
        )
        #endif
        return rows
      }()
    ),
    SectionModel(
      title: FKExamplesI18n.string("examples.scenario.examples_fkuikit_tabbar_scenarios_performance_fk.performance.63c9045599"),
      rows: [
        RowModel(
          title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.35.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.35.subtitle"),
          make: { FKTabBarPerformanceExampleViewController() }
        ),
      ]
    ),
    SectionModel(
      title: FKExamplesI18n.string("examples.scenario.examples_fkuikit_tabbar_scenarios_dynamic_fktabb.dynamic_data.bff8b6fd49"),
      rows: [
        RowModel(
          title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.36.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.36.subtitle"),
          make: { FKTabBarDynamicDataExampleViewController() }
        ),
        RowModel(
          title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.37.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.37.subtitle"),
          make: { FKTabBarApplyChangesExampleViewController() }
        ),
        RowModel(
          title: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.38.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fktabbarexampleshubviewcontroller.38.subtitle"),
          make: { FKTabBarFKUIKitReuseExampleViewController() }
        ),
      ]
    ),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "TabBar"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    sections.count
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    sections[section].title
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    sections[section].rows.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = sections[indexPath.section].rows[indexPath.row]
    var config = cell.defaultContentConfiguration()
    config.text = row.title
    config.secondaryText = row.subtitle
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let row = sections[indexPath.section].rows[indexPath.row]
    navigationController?.pushViewController(row.make(), animated: true)
  }
}

