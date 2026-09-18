import FKUIKit
import UIKit

/// Index of FKNavigationBarScrollTransition demos, grouped by capability area.
final class FKNavigationBarScrollExamplesHubViewController: UITableViewController {
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
      title: "Basics",
      rows: [
        Row(
          title: "Transparent → solid hero",
          subtitle: "fk_navigationBarScrollEngine + .transparent / .solid + navigationItem apply",
          make: { FKNavigationBarScrollTransparentSolidExampleViewController() }
        ),
        Row(
          title: "Title fade-in",
          subtitle: "titleAlpha 0→1 while background and tint interpolate",
          make: { FKNavigationBarScrollTitleFadeExampleViewController() }
        ),
        Row(
          title: "Brand color blend",
          subtitle: "Custom from/to colors (indigo → systemBackground) with shadow ramp",
          make: { FKNavigationBarScrollBrandBlendExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Application targets",
      rows: [
        Row(
          title: "Apply to navigationBar",
          subtitle: "FKNavigationBarScrollApplicationTarget.navigationBar",
          make: { FKNavigationBarScrollApplyNavigationBarExampleViewController() }
        ),
        Row(
          title: "Apply to both",
          subtitle: "FKNavigationBarScrollApplicationTarget.both (item + bar)",
          make: { FKNavigationBarScrollApplyBothExampleViewController() }
        ),
        Row(
          title: "Callback-only (no auto apply)",
          subtitle: "appliesAppearanceAutomatically = false + onAppearanceChange",
          make: { FKNavigationBarScrollCallbackOnlyExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Progress & configuration",
      rows: [
        Row(
          title: "Offset range",
          subtitle: "startOffset / endOffset mapping; live range toggles",
          make: { FKNavigationBarScrollOffsetRangeExampleViewController() }
        ),
        Row(
          title: "Adjusted content offset",
          subtitle: "usesAdjustedContentOffset with top contentInset simulation",
          make: { FKNavigationBarScrollAdjustedOffsetExampleViewController() }
        ),
        Row(
          title: "Discrete status-bar threshold",
          subtitle: "discreteThreshold + resolvedStatusBarStyle / updatesStatusBarAppearance",
          make: { FKNavigationBarScrollStatusBarThresholdExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Observation",
      rows: [
        Row(
          title: "Manual scroll forwarding",
          subtitle: "observesAutomatically = false + fk_handleNavigationBarScroll",
          make: { FKNavigationBarScrollManualObservationExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Runtime controls",
      rows: [
        Row(
          title: "Enable, force, reload & reset",
          subtitle: "isEnabled, forceProgress, reload, reset, scroll-view helpers",
          make: { FKNavigationBarScrollRuntimeControlsExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Composition",
      rows: [
        Row(
          title: "Alongside FKSticky",
          subtitle: "Same scroll view drives nav chrome + sticky strip (manual forward)",
          make: { FKNavigationBarScrollWithStickyExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Combined",
      rows: [
        Row(
          title: "Interactive playground",
          subtitle: "Toggle apply target, observation, thresholds, endpoints live",
          make: { FKNavigationBarScrollPlaygroundExampleViewController() }
        ),
      ]
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "NavBar Scroll Transition"
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
