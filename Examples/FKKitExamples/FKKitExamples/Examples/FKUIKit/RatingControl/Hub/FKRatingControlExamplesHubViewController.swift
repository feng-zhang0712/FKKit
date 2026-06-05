import FKUIKit
import UIKit
import FKCoreKit

/// Lists ``FKRatingControl`` example screens.
final class FKRatingControlExamplesHubViewController: UITableViewController {

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
    DemoSection(title: FKExamplesI18n.string("examples.hub.fkactionsheetexampleshubviewcontroller.0.title"), items: [
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkratingcontrolexampleshubviewcontroller.0.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkratingcontrolexampleshubviewcontroller.0.subtitle"),
        factory: { FKRatingExampleInteractiveViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkratingcontrolexampleshubviewcontroller.1.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkratingcontrolexampleshubviewcontroller.1.subtitle"),
        factory: { FKRatingExampleReadOnlyViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkratingcontrolexampleshubviewcontroller.2.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkratingcontrolexampleshubviewcontroller.2.subtitle"),
        factory: { FKRatingExampleConvenienceViewController() }
      ),
    ]),
    DemoSection(title: "Icons & labels", items: [
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkratingcontrolexampleshubviewcontroller.3.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkratingcontrolexampleshubviewcontroller.3.subtitle"),
        factory: { FKRatingExampleIconPresetsViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkratingcontrolexampleshubviewcontroller.4.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkratingcontrolexampleshubviewcontroller.4.subtitle"),
        factory: { FKRatingExampleCustomIconsViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkratingcontrolexampleshubviewcontroller.5.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkratingcontrolexampleshubviewcontroller.5.subtitle"),
        factory: { FKRatingExampleLabelPlacementViewController() }
      ),
    ]),
    DemoSection(title: FKExamplesI18n.string("examples.hub.fkbuttonexampleshubviewcontroller.2.title"), items: [
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkratingcontrolexampleshubviewcontroller.6.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkratingcontrolexampleshubviewcontroller.6.subtitle"),
        factory: { FKRatingExamplePlaygroundViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkratingcontrolexampleshubviewcontroller.7.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkratingcontrolexampleshubviewcontroller.7.subtitle"),
        factory: { FKRatingExampleInteractionModesViewController() }
      ),
    ]),
    DemoSection(title: FKExamplesI18n.string("examples.hub.fki18nexampleshubviewcontroller.6.title"), items: [
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkratingcontrolexampleshubviewcontroller.8.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkratingcontrolexampleshubviewcontroller.8.subtitle"),
        factory: { FKRatingExampleSheetIntegrationViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkratingcontrolexampleshubviewcontroller.9.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkratingcontrolexampleshubviewcontroller.9.subtitle"),
        factory: { FKRatingExampleDelegateLogViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkratingcontrolexampleshubviewcontroller.10.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkratingcontrolexampleshubviewcontroller.10.subtitle"),
        factory: { FKRatingExampleSwiftUIViewController() }
      ),
    ]),
    DemoSection(title: "Layout & accessibility", items: [
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkratingcontrolexampleshubviewcontroller.11.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkratingcontrolexampleshubviewcontroller.11.subtitle"),
        factory: { FKRatingExampleEnvironmentViewController() }
      ),
    ]),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKRatingControl"
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
