import UIKit
import FKCoreKit

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
            title: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.0.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.0.subtitle"),
            make: { FKPagingContentTopPlacementExampleViewController() }
          ),
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.1.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.1.subtitle"),
            make: { FKPagingNavigationBarPlacementExampleViewController() }
          ),
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.2.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.2.subtitle"),
            make: { FKPagingExternalTabBarPlacementExampleViewController() }
          ),
        ]
      ),
      SectionModel(
        title: FKExamplesI18n.string("examples.hub.fkactionsheetexampleshubviewcontroller.0.title"),
        rows: [
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.3.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.3.subtitle"),
            make: { FKPagingBasicsExampleViewController() }
          ),
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.4.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.4.subtitle"),
            make: { FKPagingTabBarIndicatorExampleViewController() }
          ),
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.5.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.5.subtitle"),
            make: { FKPagingTabBarLayoutExampleViewController() }
          ),
        ]
      ),
      SectionModel(
        title: "Layout & lifecycle",
        rows: [
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.6.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.6.subtitle"),
            make: { FKPagingLayoutSpacingExampleViewController() }
          ),
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.7.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.7.subtitle"),
            make: { FKPagingEmptyStateExampleViewController() }
          ),
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.8.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.8.subtitle"),
            make: { FKPagingReselectScrollToTopExampleViewController() }
          ),
        ]
      ),
      SectionModel(
        title: "Configuration & control",
        rows: [
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.9.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.9.subtitle"),
            make: { FKPagingDelegateConfigurationExampleViewController() }
          ),
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.10.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.10.subtitle"),
            make: { FKPagingGateExampleViewController() }
          ),
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.11.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.11.subtitle"),
            make: { FKPagingIDSelectionExampleViewController() }
          ),
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.12.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.12.subtitle"),
            make: { FKPagingSwipeDirectionExampleViewController() }
          ),
        ]
      ),
      SectionModel(
        title: FKExamplesI18n.string("examples.scenario.examples_fkuikit_pagingcontroller_scenarios_fkpa.dynamic_content.b3110431fe"),
        rows: [
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.13.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.13.subtitle"),
            make: { FKPagingDynamicContentExampleViewController() }
          ),
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.14.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.14.subtitle"),
            make: { FKPagingSyncVisibleTabsExampleViewController() }
          ),
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.15.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.15.subtitle"),
            make: { FKPagingIncrementalChangesExampleViewController() }
          ),
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.16.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.16.subtitle"),
            make: { FKPagingDataSourceExampleViewController() }
          ),
        ]
      ),
      SectionModel(
        title: "Gestures",
        rows: [
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.17.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.17.subtitle"),
            make: { FKPagingNestedHorizontalScrollExampleViewController() }
          ),
        ]
      ),
      SectionModel(
        title: "Lazy loading",
        rows: [
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.18.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.18.subtitle"),
            make: { FKPagingLazyPagesExampleViewController() }
          ),
        ]
      ),
    ]

    #if canImport(SwiftUI)
    list.append(
      SectionModel(
        title: FKExamplesI18n.string("examples.hub.fkdividerexampleshubviewcontroller.4.title"),
        rows: [
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.19.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.19.subtitle"),
            make: { FKPagingSwiftUIBridgeExampleViewController() }
          ),
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.20.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.20.subtitle"),
            make: { FKPagingLazySwiftUIExampleViewController() }
          ),
          RowModel(
            title: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.21.title"),
            subtitle: FKExamplesI18n.string("examples.hub.fkpagingcontrollerexampleshubviewcontroller.21.subtitle"),
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
