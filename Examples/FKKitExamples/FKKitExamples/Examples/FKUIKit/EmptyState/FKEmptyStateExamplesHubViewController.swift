import UIKit
import FKCoreKit

/// Index of EmptyState demos. Sources live under `Basics/`, `Advanced/`, and `Support/`.
final class FKEmptyStateExamplesHubViewController: UITableViewController {
  private struct Row {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private let rows: [Row] = [
    Row(
      title: FKExamplesI18n.string("examples.hub.fkemptystateexampleshubviewcontroller.0.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkemptystateexampleshubviewcontroller.0.subtitle"),
      make: { FKEmptyStateBasicExampleViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkemptystateexampleshubviewcontroller.1.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkemptystateexampleshubviewcontroller.1.subtitle"),
      make: { FKEmptyStateSearchNoResultsExampleViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkemptystateexampleshubviewcontroller.2.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkemptystateexampleshubviewcontroller.2.subtitle"),
      make: { FKEmptyStateErrorRetryExampleViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkemptystateexampleshubviewcontroller.3.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkemptystateexampleshubviewcontroller.3.subtitle"),
      make: { FKEmptyStateOfflineExampleViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkemptystateexampleshubviewcontroller.4.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkemptystateexampleshubviewcontroller.4.subtitle"),
      make: { FKEmptyStatePermissionDeniedExampleViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkemptystateexampleshubviewcontroller.5.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkemptystateexampleshubviewcontroller.5.subtitle"),
      make: { FKEmptyStateLoadingTransitionExampleViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkemptystateexampleshubviewcontroller.6.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkemptystateexampleshubviewcontroller.6.subtitle"),
      make: { FKEmptyStateLayoutComparisonExampleViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkemptystateexampleshubviewcontroller.7.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkemptystateexampleshubviewcontroller.7.subtitle"),
      make: { FKEmptyStateCustomIllustrationExampleViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkemptystateexampleshubviewcontroller.8.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkemptystateexampleshubviewcontroller.8.subtitle"),
      make: { FKEmptyStateDarkModeExampleViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkemptystateexampleshubviewcontroller.9.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkemptystateexampleshubviewcontroller.9.subtitle"),
      make: { FKEmptyStateRTLExampleViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkemptystateexampleshubviewcontroller.10.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkemptystateexampleshubviewcontroller.10.subtitle"),
      make: { FKEmptyStateI18nExampleViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkemptystateexampleshubviewcontroller.11.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkemptystateexampleshubviewcontroller.11.subtitle"),
      make: { FKEmptyStateResolverExampleViewController() }
    ),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    FKEmptyStateExampleFactory.configureGlobalStyleIfNeeded()
    title = "FKEmptyState"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.rowHeight = 72
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    rows.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = rows[indexPath.row]
    var content = cell.defaultContentConfiguration()
    content.text = row.title
    content.secondaryText = row.subtitle
    content.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = content
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let destination = rows[indexPath.row].make()
    navigationController?.pushViewController(destination, animated: true)
  }
}
