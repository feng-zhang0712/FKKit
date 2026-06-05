import FKUIKit
import UIKit

/// Hub for brand-inspired FKRefresh presets (`Inspired/Presets/`, `Inspired/Support/`).
final class FKRefreshInspiredExamplesHubViewController: UITableViewController {

  private struct Row {
    let preset: FKRefreshAppStylePreset
    let highlights: String
  }

  private let rows: [Row] = FKRefreshAppStylePreset.allCases.map { preset in
    let extra: String
    switch preset {
    case .indicatorOnly:
      extra = "API: `FKRefreshConfiguration.statusTextMode = .indicatorOnly`."
    case .twitter:
      extra = "API: indicator-only + `finishedHoldDuration = 0` + `noMoreDataBehavior = .hideFooter`."
    case .instagram:
      extra = "API: `defaultContentLayout = .vertical` + indicator-only terminal states."
    case .weChat:
      extra = "API: full `FKRefreshText` copy + horizontal layout."
    case .tikTokFeed:
      extra = "API: `loadMorePreloadOffset` + hide footer at end of feed."
    case .reddit:
      extra = "API: full status text + tap-to-retry failure footer."
    case .appleMail:
      extra = "API: stock `FKRefreshConfiguration.default` tuning."
    }
    return Row(preset: preset, highlights: extra)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Inspired by apps"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    rows.count
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    "Deep simulations using FKRefresh presets"
  }

  override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    "Toggle Fail in the navigation bar to exercise error/retry paths. Pull to refresh or scroll to the bottom to load more."
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = rows[indexPath.row]
    var config = cell.defaultContentConfiguration()
    config.text = row.preset.bundle.screenTitle
    config.secondaryText = "\(row.preset.bundle.summary)\n\(row.highlights)"
    config.secondaryTextProperties.numberOfLines = 0
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let bundle = rows[indexPath.row].preset.bundle
    let vc = FKRefreshInspiredFeedExampleViewController(preset: bundle)
    navigationController?.pushViewController(vc, animated: true)
  }
}
