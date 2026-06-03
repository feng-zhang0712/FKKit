import UIKit

/// Index of `FKPagingController` scenarios grouped by integration topic.
final class FKPagingControllerExamplesHubViewController: UITableViewController {
  private struct SectionModel {
    let title: String
    let rows: [RowModel]
  }

  private struct RowModel {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private let sections: [SectionModel] = {
    var list: [SectionModel] = [
      SectionModel(
        title: "Tab bar placement",
        rows: [
          RowModel(
            title: "Content area (top)",
            subtitle: "tabBarPlacement .contentTop — strip inside pager view below nav bar (default).",
            make: { FKPagingContentTopPlacementExampleViewController() }
          ),
          RowModel(
            title: "Navigation bar tabs",
            subtitle: "tabBarPlacement .navigationBar — 18 mixed tab styles, half-height pager, inline config panel.",
            make: { FKPagingNavigationBarPlacementExampleViewController() }
          ),
          RowModel(
            title: "External tab strip",
            subtitle: "tabBarPlacement .external — host adds tabBar above pages; isTabBarExternallyManaged.",
            make: { FKPagingExternalTabBarPlacementExampleViewController() }
          ),
        ]
      ),
      SectionModel(
        title: "Basics",
        rows: [
          RowModel(
            title: "Basics (eager)",
            subtitle: "Two-way tab sync, nested list, Stress x20 queue test (non-animated bursts).",
            make: { FKPagingBasicsExampleViewController() }
          ),
          RowModel(
            title: "Tab bar indicators",
            subtitle: "tabConfiguration + FKTabBarCustomization for line, pill, and custom z-order.",
            make: { FKPagingTabBarIndicatorExampleViewController() }
          ),
          RowModel(
            title: "Tab bar layout",
            subtitle: "widthMode, selectionScrollPosition, contentAlignment via pagingController.tabBar.",
            make: { FKPagingTabBarLayoutExampleViewController() }
          ),
        ]
      ),
      SectionModel(
        title: "Layout & lifecycle",
        rows: [
          RowModel(
            title: "Layout & spacing",
            subtitle: "tabBarPlacement .contentBottom; interPageSpacing visible only while swiping.",
            make: { FKPagingLayoutSpacingExampleViewController() }
          ),
          RowModel(
            title: "Empty state",
            subtitle: "emptyStateConfiguration when pageCount is zero; populate via setContent.",
            make: { FKPagingEmptyStateExampleViewController() }
          ),
          RowModel(
            title: "Reselect scroll to top",
            subtitle: "reselectBehavior .scrollPageToTop when re-tapping the active tab.",
            make: { FKPagingReselectScrollToTopExampleViewController() }
          ),
        ]
      ),
      SectionModel(
        title: "Configuration & control",
        rows: [
          RowModel(
            title: "Delegate & configuration",
            subtitle: "Phases, progress, combined transition, gesture policy, nested scroll toggle.",
            make: { FKPagingDelegateConfigurationExampleViewController() }
          ),
          RowModel(
            title: "Controlled gate",
            subtitle: "pageSwitchGateScope tab / swipe / all, shouldSwitchTo veto, commit / cancel.",
            make: { FKPagingGateExampleViewController() }
          ),
          RowModel(
            title: "ID selection",
            subtitle: "setSelectedIndex(forItemID:), selectedItemID after tab reorder.",
            make: { FKPagingIDSelectionExampleViewController() }
          ),
          RowModel(
            title: "Directional swipe",
            subtitle: "allowsSwipePagingTo blocks forward swipe from a specific page.",
            make: { FKPagingSwipeDirectionExampleViewController() }
          ),
        ]
      ),
      SectionModel(
        title: "Dynamic content",
        rows: [
          RowModel(
            title: "Dynamic setContent",
            subtitle: "Toggle between 3 and 8 tabs to exercise reload + selection preservation.",
            make: { FKPagingDynamicContentExampleViewController() }
          ),
          RowModel(
            title: "Sync visible tabs",
            subtitle: "Runtime isHidden toggles realigned with setContent(tabs:viewControllers:).",
            make: { FKPagingSyncVisibleTabsExampleViewController() }
          ),
          RowModel(
            title: "applyContentChanges",
            subtitle: "Lazy incremental tab updates and invalidatePage without full setContent.",
            make: { FKPagingIncrementalChangesExampleViewController() }
          ),
          RowModel(
            title: "Data source",
            subtitle: "FKPagingEagerDataSource with reloadFromDataSource() add/remove pages.",
            make: { FKPagingDataSourceExampleViewController() }
          ),
        ]
      ),
      SectionModel(
        title: "Gestures",
        rows: [
          RowModel(
            title: "Nested horizontal scroll",
            subtitle: "preferNestedHorizontalScroll installs require(toFail:) on in-page carousels.",
            make: { FKPagingNestedHorizontalScrollExampleViewController() }
          ),
        ]
      ),
      SectionModel(
        title: "Lazy loading",
        rows: [
          RowModel(
            title: "Lazy pages (UIKit)",
            subtitle: "Factory-driven pages, preload/retention, lifecycle log, invalidatePage(at:).",
            make: { FKPagingLazyPagesExampleViewController() }
          ),
        ]
      ),
    ]

    #if canImport(SwiftUI)
    list.append(
      SectionModel(
        title: "SwiftUI",
        rows: [
          RowModel(
            title: "SwiftUI representable",
            subtitle: "Eager pages with $selectedIndex mirrored under the pager.",
            make: { FKPagingSwiftUIBridgeExampleViewController() }
          ),
          RowModel(
            title: "SwiftUI lazy provider",
            subtitle: "FKPagingControllerRepresentable with pageCount + factory closure binding.",
            make: { FKPagingLazySwiftUIExampleViewController() }
          ),
          RowModel(
            title: "SwiftUI advanced",
            subtitle: "$selectedItemID binding plus FKPagingControllerRepresentableCallbacks telemetry.",
            make: { FKPagingSwiftUIAdvancedExampleViewController() }
          ),
        ]
      )
    )
    #endif

    return list
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "PagingController"
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
