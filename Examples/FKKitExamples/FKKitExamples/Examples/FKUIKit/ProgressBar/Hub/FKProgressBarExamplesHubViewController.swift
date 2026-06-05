import FKUIKit
import UIKit
import FKCoreKit

/// Lists ``FKProgressBar`` example screens.
final class FKProgressBarExamplesHubViewController: UITableViewController {

  init() {
    super.init(style: .insetGrouped)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

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
    DemoSection(title: FKExamplesI18n.string("examples.scenario.examples_fkuikit_ratingcontrol_scenarios_fkratin.interactive.a9abf5059b"), items: [
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkprogressbarexampleshubviewcontroller.0.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkprogressbarexampleshubviewcontroller.0.subtitle"),
        factory: { FKProgressBarPlaygroundDemoViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkprogressbarexampleshubviewcontroller.1.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkprogressbarexampleshubviewcontroller.1.subtitle"),
        factory: { FKProgressBarProgressButtonDemoViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkprogressbarexampleshubviewcontroller.2.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkprogressbarexampleshubviewcontroller.2.subtitle"),
        factory: { FKProgressBarGalleryDemoViewController() }
      ),
    ]),
    DemoSection(title: FKExamplesI18n.string("examples.hub.fki18nexampleshubviewcontroller.6.title"), items: [
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkprogressbarexampleshubviewcontroller.3.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkprogressbarexampleshubviewcontroller.3.subtitle"),
        factory: { FKProgressBarDelegateLogDemoViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkprogressbarexampleshubviewcontroller.4.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkprogressbarexampleshubviewcontroller.4.subtitle"),
        factory: { FKProgressBarSwiftUIDemoViewController() }
      ),
    ]),
    DemoSection(title: "Layout & accessibility", items: [
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkprogressbarexampleshubviewcontroller.5.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkprogressbarexampleshubviewcontroller.5.subtitle"),
        factory: { FKProgressBarEnvironmentDemoViewController() }
      ),
    ]),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKProgressBar"
    navigationItem.largeTitleDisplayMode = .never
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
