import UIKit
import FKCoreKit

final class FKToastExamplesHubViewController: UITableViewController {
  private struct Row {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private let rows: [Row] = [
    Row(
      title: FKExamplesI18n.string("examples.hub.fktoastexampleshubviewcontroller.0.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fktoastexampleshubviewcontroller.0.subtitle"),
      make: { FKToastBasicsExampleViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fktoastexampleshubviewcontroller.1.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fktoastexampleshubviewcontroller.1.subtitle"),
      make: { FKToastQueueStrategyExampleViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fktoastexampleshubviewcontroller.2.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fktoastexampleshubviewcontroller.2.subtitle"),
      make: { FKToastLiveUpdateExampleViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fktoastexampleshubviewcontroller.3.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fktoastexampleshubviewcontroller.3.subtitle"),
      make: { FKToastHUDExampleViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fktoastexampleshubviewcontroller.4.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fktoastexampleshubviewcontroller.4.subtitle"),
      make: { FKToastSnackbarExampleViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fktoastexampleshubviewcontroller.5.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fktoastexampleshubviewcontroller.5.subtitle"),
      make: { FKToastEnvironmentExampleViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fktoastexampleshubviewcontroller.6.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fktoastexampleshubviewcontroller.6.subtitle"),
      make: { FKToastSwiftUIHostViewController() }
    ),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKToast"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = rows[indexPath.row]
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
    navigationController?.pushViewController(rows[indexPath.row].make(), animated: true)
  }
}
