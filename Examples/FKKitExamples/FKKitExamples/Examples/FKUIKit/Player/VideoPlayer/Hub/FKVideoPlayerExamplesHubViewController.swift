import FKUIKit
import UIKit
import FKCoreKit

/// Lists ``FKVideoPlayer`` example screens grouped by feature area.
final class FKVideoPlayerExamplesHubViewController: UITableViewController {

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
    DemoSection(title: FKExamplesI18n.string("examples.hub.fkactionsheetexampleshubviewcontroller.0.title"), items: [
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.0.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.0.subtitle"),
        factory: { FKVideoPlayerProgressiveExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.1.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.1.subtitle"),
        factory: { FKVideoPlayerHLSVODExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.2.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.2.subtitle"),
        factory: { FKVideoPlayerEmbedHelperExampleViewController() }
      ),
    ]),
    DemoSection(title: "Playback", items: [
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.3.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.3.subtitle"),
        factory: { FKVideoPlayerPlaylistExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.4.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.4.subtitle"),
        factory: { FKVideoPlayerPlaygroundExampleViewController() }
      ),
    ]),
    DemoSection(title: "Live", items: [
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.5.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.5.subtitle"),
        factory: { FKVideoPlayerLiveExampleViewController() }
      ),
    ]),
    DemoSection(title: "Subtitles & tracks", items: [
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.6.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.6.subtitle"),
        factory: { FKVideoPlayerSubtitlesExampleViewController() }
      ),
    ]),
    DemoSection(title: "UI & chrome", items: [
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.7.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.7.subtitle"),
        factory: { FKVideoPlayerFullscreenExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.8.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.8.subtitle"),
        factory: { FKVideoPlayerCustomControlsExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.9.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.9.subtitle"),
        factory: { FKVideoPlayerMiniPlayerExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.10.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.10.subtitle"),
        factory: { FKVideoPlayerSwiftUIExampleViewController() }
      ),
    ]),
    DemoSection(title: "Feed & performance", items: [
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.11.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.11.subtitle"),
        factory: { FKVideoPlayerFeedExampleViewController() }
      ),
    ]),
    DemoSection(title: FKExamplesI18n.string("examples.hub.fki18nexampleshubviewcontroller.6.title"), items: [
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.12.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.12.subtitle"),
        factory: { FKMediaExtendedEngineExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.13.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.13.subtitle"),
        factory: { FKVideoPlayerDelegateLogExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.14.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.14.subtitle"),
        factory: { FKVideoPlayerOfflineExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.15.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.15.subtitle"),
        factory: { FKVideoPlayerAdsExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.16.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.16.subtitle"),
        factory: { FKVideoPlayerQoEExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.17.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkvideoplayerexampleshubviewcontroller.17.subtitle"),
        factory: { FKVideoPlayerSharePlayExampleViewController() }
      ),
    ]),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKVideoPlayer"
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
