import UIKit
import FKCoreKit
import FKUIKit

// MARK: - Hub

final class FKBlurViewExamplesHubViewController: UITableViewController {
  private struct Row {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private let rows: [Row] = [
    Row(title: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.0.title"), subtitle: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.0.subtitle"), make: { FKBlurBasicVC() }),
    Row(title: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.1.title"), subtitle: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.1.subtitle"), make: { FKBlurAllSystemStylesVC() }),
    Row(title: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.2.title"), subtitle: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.2.subtitle"), make: { FKBlurCustomRadiusVC() }),
    Row(title: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.3.title"), subtitle: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.3.subtitle"), make: { FKBlurCustomSaturationVC() }),
    Row(title: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.4.title"), subtitle: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.4.subtitle"), make: { FKBlurCustomBrightnessVC() }),
    Row(title: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.5.title"), subtitle: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.5.subtitle"), make: { FKBlurCustomTintVC() }),
    Row(title: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.6.title"), subtitle: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.6.subtitle"), make: { FKBlurStaticVC() }),
    Row(title: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.7.title"), subtitle: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.7.subtitle"), make: { FKBlurDynamicScrollVC() }),
    Row(title: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.8.title"), subtitle: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.8.subtitle"), make: { FKBlurImageBlurVC() }),
    Row(title: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.9.title"), subtitle: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.9.subtitle"), make: { FKBlurUIViewSnapshotVC() }),
    Row(title: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.10.title"), subtitle: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.10.subtitle"), make: { FKBlurRoundedRectVC() }),
    Row(title: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.11.title"), subtitle: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.11.subtitle"), make: { FKBlurCircleVC() }),
    Row(title: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.12.title"), subtitle: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.12.subtitle"), make: { FKBlurCustomMaskVC() }),
    Row(title: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.13.title"), subtitle: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.13.subtitle"), make: { FKBlurOpacityVC() }),
    Row(title: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.14.title"), subtitle: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.14.subtitle"), make: { FKBlurGlobalConfigVC() }),
    Row(title: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.15.title"), subtitle: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.15.subtitle"), make: { FKBlurXIBDemoVC() }),
    Row(title: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.16.title"), subtitle: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.16.subtitle"), make: { FKBlurSwiftUIHostVC() }),
    Row(title: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.17.title"), subtitle: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.17.subtitle"), make: { FKBlurDarkModeVC() }),
    Row(title: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.18.title"), subtitle: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.18.subtitle"), make: { FKBlurRotationVC() }),
    Row(title: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.19.title"), subtitle: FKExamplesI18n.string("examples.hub.fkblurexampleshubviewcontroller.19.subtitle"), make: { FKBlurPerformanceTestVC() }),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKBlurView"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = rows[indexPath.row]
    var cfg = cell.defaultContentConfiguration()
    cfg.text = row.title
    cfg.secondaryText = row.subtitle
    cfg.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = cfg
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    navigationController?.pushViewController(rows[indexPath.row].make(), animated: true)
  }
}
