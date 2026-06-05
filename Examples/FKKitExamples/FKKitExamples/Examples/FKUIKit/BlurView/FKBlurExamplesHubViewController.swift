import UIKit
import FKUIKit

// MARK: - Hub

final class FKBlurViewExamplesHubViewController: UITableViewController {
  private struct Row {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private struct Section {
    let title: String
    let rows: [Row]
  }

  private let sections: [Section] = [
    Section(
      title: "Getting started",
      rows: [
        Row(title: "Basic Blur View", subtitle: "The simplest FKBlurView (system material)", make: { FKBlurBasicVC() }),
        Row(title: "All System Styles", subtitle: "Preview light/dark/extraLight/systemMaterial…", make: { FKBlurAllSystemStylesVC() }),
      ]
    ),
    Section(
      title: "Visual tuning",
      rows: [
        Row(title: "Custom Blur Radius", subtitle: "Custom blurRadius demo", make: { FKBlurCustomRadiusVC() }),
        Row(title: "Custom Saturation", subtitle: "Custom saturation demo", make: { FKBlurCustomSaturationVC() }),
        Row(title: "Custom Brightness", subtitle: "Custom brightness demo", make: { FKBlurCustomBrightnessVC() }),
        Row(title: "Custom Tint Overlay", subtitle: "Custom tintColor + tintOpacity demo", make: { FKBlurCustomTintVC() }),
      ]
    ),
    Section(
      title: "Blur modes",
      rows: [
        Row(title: "Static Blur", subtitle: "mode = .static (blur once, maximum performance)", make: { FKBlurStaticVC() }),
        Row(title: "Dynamic Blur (Scroll)", subtitle: "mode = .dynamic (refresh while scrolling)", make: { FKBlurDynamicScrollVC() }),
      ]
    ),
    Section(
      title: "Extensions",
      rows: [
        Row(title: "Image Blur", subtitle: "UIImage.fk_blurred(...) demo", make: { FKBlurImageBlurVC() }),
        Row(title: "UIView Snapshot Blur", subtitle: "UIView.fk_blurredSnapshot sync/async demo", make: { FKBlurUIViewSnapshotVC() }),
      ]
    ),
    Section(
      title: "Shape & mask",
      rows: [
        Row(title: "Rounded Rect Blur", subtitle: "maskedCornerRadius demo", make: { FKBlurRoundedRectVC() }),
        Row(title: "Circular Blur", subtitle: "maskPath = ovalInRect demo", make: { FKBlurCircleVC() }),
        Row(title: "Custom Mask", subtitle: "Arbitrary maskPath demo", make: { FKBlurCustomMaskVC() }),
        Row(title: "Semi-Transparent Blur", subtitle: "opacity demo", make: { FKBlurOpacityVC() }),
      ]
    ),
    Section(
      title: "Configuration & integration",
      rows: [
        Row(title: "Global Defaults", subtitle: "FKBlur.defaultConfiguration demo", make: { FKBlurGlobalConfigVC() }),
        Row(title: "XIB / Storyboard", subtitle: "Load a FKBlurView from a XIB", make: { FKBlurXIBDemoVC() }),
        Row(title: "SwiftUI Demo", subtitle: "FKSwiftUIBlurView demo", make: { FKBlurSwiftUIHostVC() }),
      ]
    ),
    Section(
      title: "Environment & performance",
      rows: [
        Row(title: "Dark Mode", subtitle: "Switch Light/Dark and inspect materials", make: { FKBlurDarkModeVC() }),
        Row(title: "Rotation", subtitle: "Auto Layout + refresh after rotation", make: { FKBlurRotationVC() }),
        Row(title: "Scroll Performance", subtitle: "Validate smooth 60fps scrolling", make: { FKBlurPerformanceTestVC() }),
      ]
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKBlurView"
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
    let row = sections[indexPath.section].rows[indexPath.row]
    navigationController?.pushViewController(row.make(), animated: true)
  }
}
