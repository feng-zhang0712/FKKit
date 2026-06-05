import FKUIKit
import UIKit
import FKCoreKit

/// Entry list for FKRefresh samples (`Scenarios/`, `SwiftUI/`, `Shared/`, `Support/`).
final class FKRefreshExamplesHubViewController: UITableViewController {
  private struct DemoItem {
    let title: String
    let subtitle: String
    let factory: () -> UIViewController
  }

  private struct DemoSection {
    let title: String
    let items: [DemoItem]
  }

  private lazy var sections: [DemoSection] = [
    DemoSection(title: "Core scenarios", items: [
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.0.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.0.subtitle"),
        factory: { FKRefreshDefaultDemoViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.1.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.1.subtitle"),
        factory: { FKRefreshCollectionDemoViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.2.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.2.subtitle"),
        factory: { FKRefreshScrollViewDemoViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.3.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.3.subtitle"),
        factory: { FKRefreshAsyncAwaitExampleViewController() }
      ),
    ]),
    DemoSection(title: "Indicators & configuration", items: [
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.4.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.4.subtitle"),
        factory: { FKRefreshConfigurationDemoViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.5.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.5.subtitle"),
        factory: { FKRefreshContentLayoutDemoViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.6.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.6.subtitle"),
        factory: { FKRefreshDotsDemoViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.7.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.7.subtitle"),
        factory: { FKRefreshGIFDemoViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.8.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.8.subtitle"),
        factory: { FKRefreshHostedDemoViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.9.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.9.subtitle"),
        factory: {
          FKRefreshInspiredFeedExampleViewController(preset: FKRefreshAppStylePreset.indicatorOnly.bundle)
        }
      ),
    ]),
    DemoSection(title: "Inspired by popular apps", items: [
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.10.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.10.subtitle"),
        factory: { FKRefreshInspiredExamplesHubViewController() }
      ),
    ]),
    DemoSection(title: "Policy & state", items: [
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.11.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.11.subtitle"),
        factory: { FKRefreshPolicyStressExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.12.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.12.subtitle"),
        factory: { FKRefreshDelegateDemoViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.13.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.13.subtitle"),
        factory: { FKRefreshPaginationDemoViewController() }
      ),
    ]),
    DemoSection(title: "Globals & environment", items: [
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.14.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.14.subtitle"),
        factory: { FKRefreshGlobalSettingsDemoViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.15.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.15.subtitle"),
        factory: { FKRefreshComplexEnvironmentDemoViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.16.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.16.subtitle"),
        factory: { FKRefreshLocalizationAccessibilityDemoViewController() }
      ),
    ]),
    DemoSection(title: FKExamplesI18n.string("examples.hub.fktoastexampleshubviewcontroller.6.title"), items: [
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.17.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkrefreshexampleshubviewcontroller.17.subtitle"),
        factory: { FKRefreshSwiftUIBridgeDemoViewController() }
      ),
    ]),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKRefresh"
    navigationItem.largeTitleDisplayMode = .never
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
    navigationController?.navigationBar.prefersLargeTitles = false
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    sections.count
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    sections[section].title
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    sections[section].items.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = sections[indexPath.section].items[indexPath.row]
    var config = cell.defaultContentConfiguration()
    config.text = row.title
    config.secondaryText = row.subtitle
    config.secondaryTextProperties.numberOfLines = 0
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let vc = sections[indexPath.section].items[indexPath.row].factory()
    navigationController?.pushViewController(vc, animated: true)
  }
}
