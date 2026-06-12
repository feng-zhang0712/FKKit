import UIKit

/// Grouped index of ``FKQRCodeGenerator`` and ``FKQRCodeParser`` examples.
final class FKQRCodeExamplesHubViewController: UITableViewController {
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
      title: "Generation",
      rows: [
        Row(
          title: "Generate basics",
          subtitle: "FKQRCodeGenerator.makeImage — default options, URL payload",
          make: { FKQRCodeExampleGenerateBasicsViewController() }
        ),
        Row(
          title: "Correction levels",
          subtitle: "L / M / Q / H side-by-side comparison at 160 pt",
          make: { FKQRCodeExampleCorrectionLevelsViewController() }
        ),
        Row(
          title: "Colors & size",
          subtitle: "Custom foreground/background colors and output dimensions",
          make: { FKQRCodeExampleColorsAndSizeViewController() }
        ),
        Row(
          title: "Logo embedding",
          subtitle: "FKQRCodeLogoEmbedding — auto correction H, max 22% area",
          make: { FKQRCodeExampleLogoEmbeddingViewController() }
        ),
        Row(
          title: "CIImage output",
          subtitle: "makeCIImage → CGImage bitmap path without logo compositing",
          make: { FKQRCodeExampleCIImageViewController() }
        ),
        Row(
          title: "Generation errors",
          subtitle: "emptyContent, contentTooLong — FKQRCodeError cases",
          make: { FKQRCodeExampleGenerationErrorsViewController() }
        ),
      ]
    ),
    Section(
      title: "Parsing",
      rows: [
        Row(
          title: "Parser payloads",
          subtitle: "FKQRCodeParser — URL, plain text, custom scheme, unknown",
          make: { FKQRCodeExampleParserViewController() }
        ),
      ]
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKQRCode (Core)"
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
