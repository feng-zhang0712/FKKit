import FKUIKit
import UIKit
import FKCoreKit

/// Lists ``FKAudioPlayer`` example screens grouped by feature area.
final class FKAudioPlayerExamplesHubViewController: UITableViewController {

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
        title: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.0.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.0.subtitle"),
        factory: { FKAudioPlayerMP3ExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.1.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.1.subtitle"),
        factory: { FKAudioPlayerHLSExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.2.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.2.subtitle"),
        factory: { FKAudioPlayerEmbedHelperExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.3.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.3.subtitle"),
        factory: { FKAudioPlayerCompactStyleExampleViewController() }
      ),
    ]),
    DemoSection(title: "Queue", items: [
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.4.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.4.subtitle"),
        factory: { FKAudioPlayerSequentialQueueExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.5.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.5.subtitle"),
        factory: { FKAudioPlayerShuffleExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.6.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.6.subtitle"),
        factory: { FKAudioPlayerRepeatModesExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.7.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.7.subtitle"),
        factory: { FKAudioPlayerQueueEditingExampleViewController() }
      ),
    ]),
    DemoSection(title: "Lyrics & podcast", items: [
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.8.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.8.subtitle"),
        factory: { FKAudioPlayerLRCLyricsExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.9.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.9.subtitle"),
        factory: { FKAudioPlayerPlainLyricsExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.10.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.10.subtitle"),
        factory: { FKAudioPlayerChaptersExampleViewController() }
      ),
    ]),
    DemoSection(title: "UI & chrome", items: [
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.11.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.11.subtitle"),
        factory: { FKAudioPlayerMiniBarExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.12.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.12.subtitle"),
        factory: { FKAudioPlayerNowPlayingExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.13.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.13.subtitle"),
        factory: { FKAudioPlayerSwiftUIExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.14.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.14.subtitle"),
        factory: { FKAudioPlayerWaveformExampleViewController() }
      ),
    ]),
    DemoSection(title: "Tools", items: [
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.15.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.15.subtitle"),
        factory: { FKAudioPlayerSleepTimerExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.16.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.16.subtitle"),
        factory: { FKAudioPlayerStopAfterCurrentExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.17.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.17.subtitle"),
        factory: { FKAudioPlayerPlaygroundExampleViewController() }
      ),
    ]),
    DemoSection(title: FKExamplesI18n.string("examples.hub.fki18nexampleshubviewcontroller.6.title"), items: [
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.18.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.18.subtitle"),
        factory: { FKAudioPlayerLockScreenExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.19.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.19.subtitle"),
        factory: { FKAudioPlayerDelegateLogExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.20.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.20.subtitle"),
        factory: { FKAudioPlayerHistoryExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.21.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.21.subtitle"),
        factory: { FKAudioPlayerQoEExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.22.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.22.subtitle"),
        factory: { FKAudioPlayerWatchWidgetExampleViewController() }
      ),
      DemoItem(
        title: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.23.title"),
        subtitle: FKExamplesI18n.string("examples.hub.fkaudioplayerexampleshubviewcontroller.23.subtitle"),
        factory: { FKAudioPlayerCarPlayExampleViewController() }
      ),
    ]),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKAudioPlayer"
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
