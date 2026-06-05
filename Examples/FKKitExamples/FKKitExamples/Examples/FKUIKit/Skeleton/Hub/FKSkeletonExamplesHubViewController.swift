import UIKit
import FKCoreKit

/// Skeleton demo hub (`Examples/.../Skeleton/Hub`). Scenario view controllers live in `Scenarios/`; shared UI in `Support/`.
final class FKSkeletonExamplesHubViewController: UITableViewController {

  private struct Row {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private let rows: [Row] = [
    Row(
      title: FKExamplesI18n.string("examples.hub.fkskeletonexampleshubviewcontroller.0.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkskeletonexampleshubviewcontroller.0.subtitle"),
      make: { FKSkeletonExampleOverlayViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkskeletonexampleshubviewcontroller.1.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkskeletonexampleshubviewcontroller.1.subtitle"),
      make: { FKSkeletonExampleAutoDisplayOptionsViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkskeletonexampleshubviewcontroller.2.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkskeletonexampleshubviewcontroller.2.subtitle"),
      make: { FKSkeletonExampleOverridesViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkskeletonexampleshubviewcontroller.3.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkskeletonexampleshubviewcontroller.3.subtitle"),
      make: { FKSkeletonExampleLoadingHelpersViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkskeletonexampleshubviewcontroller.4.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkskeletonexampleshubviewcontroller.4.subtitle"),
      make: { FKSkeletonExampleManagerViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkskeletonexampleshubviewcontroller.5.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkskeletonexampleshubviewcontroller.5.subtitle"),
      make: { FKSkeletonExampleAnimationEffectsViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkskeletonexampleshubviewcontroller.6.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkskeletonexampleshubviewcontroller.6.subtitle"),
      make: { FKSkeletonExampleStandaloneBlocksViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkskeletonexampleshubviewcontroller.7.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkskeletonexampleshubviewcontroller.7.subtitle"),
      make: { FKSkeletonExampleContainerViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkskeletonexampleshubviewcontroller.8.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkskeletonexampleshubviewcontroller.8.subtitle"),
      make: { FKSkeletonExamplePresetsViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkskeletonexampleshubviewcontroller.9.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkskeletonexampleshubviewcontroller.9.subtitle"),
      make: { FKSkeletonExampleGlobalDefaultsViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkskeletonexampleshubviewcontroller.10.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkskeletonexampleshubviewcontroller.10.subtitle"),
      make: { FKSkeletonExampleTableSkeletonCellViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkskeletonexampleshubviewcontroller.11.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkskeletonexampleshubviewcontroller.11.subtitle"),
      make: { FKSkeletonExampleTableOverlayVisibleViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkskeletonexampleshubviewcontroller.12.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkskeletonexampleshubviewcontroller.12.subtitle"),
      make: { FKSkeletonExampleCollectionSkeletonCellViewController() }
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkskeletonexampleshubviewcontroller.13.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkskeletonexampleshubviewcontroller.13.subtitle"),
      make: { FKSkeletonExampleCollectionAutoVisibleViewController() }
    ),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKSkeleton"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 76
    tableView.cellLayoutMarginsFollowReadableWidth = true
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
    navigationController?.pushViewController(rows[indexPath.row].make(), animated: true)
  }
}
