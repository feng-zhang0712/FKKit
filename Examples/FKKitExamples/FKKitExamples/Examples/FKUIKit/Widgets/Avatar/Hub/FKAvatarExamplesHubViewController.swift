import FKUIKit
import UIKit

/// Grouped index for ``FKAvatar``, ``FKAvatarGroup``, and ``FKPresenceIndicator`` demos.
final class FKAvatarExamplesHubViewController: UITableViewController {

  init() {
    super.init(style: .insetGrouped)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private struct DemoItem {
    let title: String
    let subtitle: String
    let factory: () -> UIViewController
  }

  private struct DemoSection {
    let title: String
    let items: [DemoItem]
  }

  private lazy var sections: [DemoSection] = [
    DemoSection(title: "FKAvatar · Content", items: [
      DemoItem(
        title: "Sizes & shapes",
        subtitle: "XS–XL presets, circle, squircle, rounded rectangle, local bitmap.",
        factory: { FKAvatarExampleSizesShapesViewController() }
      ),
      DemoItem(
        title: "Initials fallback",
        subtitle: "Latin two-letter, CJK first grapheme, empty-name placeholder.",
        factory: { FKAvatarExampleInitialsViewController() }
      ),
      DemoItem(
        title: "Remote URL loading",
        subtitle: "FKImageView pipeline, skeleton loading, success transition.",
        factory: { FKAvatarExampleRemoteURLViewController() }
      ),
      DemoItem(
        title: "Failure & tap retry",
        subtitle: "HTTP 404, failed state, interaction.retriesOnFailure.",
        factory: { FKAvatarExampleFailureRetryViewController() }
      ),
    ]),
    DemoSection(title: "FKAvatar · Chrome & layout", items: [
      DemoItem(
        title: "Profile header",
        subtitle: "XL size, story gradient ring, border stroke, verified badge.",
        factory: { FKAvatarExampleProfileHeaderViewController() }
      ),
      DemoItem(
        title: "Navigation bar avatar",
        subtitle: "Size S in bar button item, 44×44 pt expanded hit area.",
        factory: { FKAvatarExampleNavigationBarViewController() }
      ),
      DemoItem(
        title: "Configuration playground",
        subtitle: "Live toggles for size, shape, presence, story ring, interaction.",
        factory: { FKAvatarExamplePlaygroundViewController() }
      ),
    ]),
    DemoSection(title: "FKAvatar · Integration", items: [
      DemoItem(
        title: "Presence & badge",
        subtitle: "Attached presence dot, runtime presenceState, FKBadgeController.",
        factory: { FKAvatarExamplePresenceBadgeViewController() }
      ),
      DemoItem(
        title: "List reuse stress",
        subtitle: "UITableView fast scroll, resetForReuse(), URL identity.",
        factory: { FKAvatarExampleListReuseViewController() }
      ),
    ]),
    DemoSection(title: "FKAvatarGroup", items: [
      DemoItem(
        title: "Collaborator stack",
        subtitle: "Overlap, +N overflow, onAvatarTap, onOverflowTap, separator border.",
        factory: { FKAvatarExampleGroupViewController() }
      ),
    ]),
    DemoSection(title: "FKPresenceIndicator", items: [
      DemoItem(
        title: "All presence states",
        subtitle: "Online/offline/busy/away/custom, S/M/L sizes, pulse & border.",
        factory: { FKAvatarExamplePresenceIndicatorViewController() }
      ),
    ]),
    DemoSection(title: "Layout & SwiftUI", items: [
      DemoItem(
        title: "RTL & appearance",
        subtitle: "Forced RTL layout, light/dark interface styles.",
        factory: { FKAvatarExampleEnvironmentViewController() }
      ),
      DemoItem(
        title: "SwiftUI bridges",
        subtitle: "FKAvatarRepresentable, FKAvatarGroupRepresentable, FKPresenceIndicatorView.",
        factory: { FKAvatarExampleSwiftUIViewController() }
      ),
    ]),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Avatar"
    navigationItem.largeTitleDisplayMode = .never
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    sections.count
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    sections[section].title
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    sections[section].items.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = sections[indexPath.section].items[indexPath.row]
    var config = cell.defaultContentConfiguration()
    config.text = row.title
    config.secondaryText = row.subtitle
    config.secondaryTextProperties.numberOfLines = 0
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    navigationController?.pushViewController(sections[indexPath.section].items[indexPath.row].factory(), animated: true)
  }
}
