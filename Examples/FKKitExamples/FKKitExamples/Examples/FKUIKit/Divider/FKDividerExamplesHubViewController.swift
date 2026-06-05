import UIKit

/// Entry table for focused FKDivider demos.
final class FKDividerExamplesHubViewController: UITableViewController {

  private struct Row {
    let title: String
    let subtitle: String
    let controllerType: UIViewController.Type
  }

  private struct Section {
    let title: String
    let rows: [Row]
  }

  private let sections: [Section] = [
    Section(
      title: "Core",
      rows: [
        Row(
          title: "Basics & layout",
          subtitle: "Horizontal, vertical, hairline, insets, thickness, color",
          controllerType: FKDividerExampleBasicsViewController.self
        ),
        Row(
          title: "Line styles & gradients",
          subtitle: "Solid, dashed patterns, gradient strokes",
          controllerType: FKDividerExampleLineStyleViewController.self
        ),
      ]
    ),
    Section(
      title: "Defaults & adaptive",
      rows: [
        Row(
          title: "Edges & defaults",
          subtitle: "Pinned edges, global defaults, Interface Builder",
          controllerType: FKDividerExampleLayoutViewController.self
        ),
        Row(
          title: "Adaptive UI",
          subtitle: "Dark mode and rotation",
          controllerType: FKDividerExampleAdaptiveViewController.self
        ),
      ]
    ),
    Section(
      title: "SwiftUI",
      rows: [
        Row(
          title: "SwiftUI",
          subtitle: "FKDividerView in a hosting controller",
          controllerType: FKDividerExampleSwiftUIViewController.self
        ),
      ]
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKDivider"
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
    let vc = row.controllerType.init(nibName: nil, bundle: nil)
    vc.title = row.title
    navigationController?.pushViewController(vc, animated: true)
  }
}
