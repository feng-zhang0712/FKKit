import UIKit

/// Grouped index of ``FKQRCodeScannerViewController`` and SwiftUI bridge examples.
final class FKQRCodeScannerExamplesHubViewController: UITableViewController {
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
        Row(
          title: "Scan basics",
          subtitle: "Present scanner, FKQRCodeScannerDelegate callbacks, default configuration",
          make: { FKQRCodeScannerExampleBasicsViewController() }
        ),
        Row(
          title: "Async scan API",
          subtitle: "FKQRCodeScannerViewController.scan(from:) — continuation wrapper",
          make: { FKQRCodeScannerExampleAsyncViewController() }
        ),
      ]
    ),
    Section(
      title: "Scan behavior",
      rows: [
        Row(
          title: "Scan modes",
          subtitle: "scanMode .once (pause after first) vs .continuous",
          make: { FKQRCodeScannerExampleScanModesViewController() }
        ),
        Row(
          title: "Debounce & cooldown",
          subtitle: "cooldownInterval + allowsMultipleCallbacks — duplicate suppression",
          make: { FKQRCodeScannerExampleDebounceViewController() }
        ),
        Row(
          title: "Overlay style",
          subtitle: "FKQRCodeOverlayStyle — scan region size, scan line animation",
          make: { FKQRCodeScannerExampleOverlayViewController() }
        ),
        Row(
          title: "Torch toggle",
          subtitle: "showsTorchButton — device torch on supported hardware",
          make: { FKQRCodeScannerExampleTorchViewController() }
        ),
      ]
    ),
    Section(
      title: "Permissions & security",
      rows: [
        Row(
          title: "Permission flows",
          subtitle: "permissionPrePrompt, denied EmptyState, Open Settings action",
          make: { FKQRCodeScannerExamplePermissionViewController() }
        ),
        Row(
          title: "Navigation policy",
          subtitle: "callbackOnly vs openHTTPInApp vs openExternally",
          make: { FKQRCodeScannerExampleNavigationPolicyViewController() }
        ),
      ]
    ),
    Section(
      title: "Integration",
      rows: [
        Row(
          title: "Mock scanner",
          subtitle: "Simulator placeholder — simulatorMockRawValue simulate button",
          make: { FKQRCodeScannerExampleMockViewController() }
        ),
        Row(
          title: "SwiftUI bridge",
          subtitle: "FKQRCodeScannerRepresentable + FKQRCodeImageView",
          make: { FKQRCodeScannerExampleSwiftUIViewController() }
        ),
      ]
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKQRCode (Scanner)"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func numberOfSections(in tableView: UITableView) -> Int { sections.count }

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
    config.secondaryTextProperties.numberOfLines = 2
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    navigationController?.pushViewController(sections[indexPath.section].rows[indexPath.row].make(), animated: true)
  }
}
