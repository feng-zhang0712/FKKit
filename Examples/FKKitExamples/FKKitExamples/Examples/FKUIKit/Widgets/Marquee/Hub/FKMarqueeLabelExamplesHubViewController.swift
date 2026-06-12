import FKUIKit
import UIKit

/// Grouped index for ``FKMarqueeLabel`` demos.
final class FKMarqueeLabelExamplesHubViewController: UITableViewController {

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
    DemoSection(title: "Display & scrolling", items: [
      DemoItem(
        title: "Long announcement",
        subtitle: "Seamless loop scrolling when text exceeds the track width; default speed, gap, and fade.",
        factory: { FKMarqueeLabelExampleLongAnnouncementViewController() }
      ),
      DemoItem(
        title: "Short text alignment",
        subtitle: "FKMarqueeLabelAlignment.leading vs .center — no scroll when text fits.",
        factory: { FKMarqueeLabelExampleShortTextViewController() }
      ),
      DemoItem(
        title: "Fade edges",
        subtitle: "animation.fadeWidth gradient mask; compare with fade disabled.",
        factory: { FKMarqueeLabelExampleFadeEdgesViewController() }
      ),
      DemoItem(
        title: "Announcement bar",
        subtitle: "Typical promo strip with leading icon and constrained marquee track.",
        factory: { FKMarqueeLabelExampleAnnouncementBarViewController() }
      ),
    ]),
    DemoSection(title: "Interaction & control", items: [
      DemoItem(
        title: "Drag to pause",
        subtitle: "interaction.pausesOnPan — hold or drag on the ticker to pause; release to resume.",
        factory: { FKMarqueeLabelExampleDragToPauseViewController() }
      ),
      DemoItem(
        title: "Programmatic pause",
        subtitle: "isPaused toggles scrolling without user gesture; resumes immediately when cleared.",
        factory: { FKMarqueeLabelExampleProgrammaticPauseViewController() }
      ),
      DemoItem(
        title: "Animation playground",
        subtitle: "Live speed, loopGap, delay, direction, and textStyle adjustments.",
        factory: { FKMarqueeLabelExamplePlaygroundViewController() }
      ),
    ]),
    DemoSection(title: "Environment & accessibility", items: [
      DemoItem(
        title: "Reduce Motion",
        subtitle: "respectsReducedMotion — static tail truncation with full VoiceOver label.",
        factory: { FKMarqueeLabelExampleReduceMotionViewController() }
      ),
      DemoItem(
        title: "RTL & appearance",
        subtitle: "mirrorsDirectionInRTL, forced RTL, light/dark interface styles.",
        factory: { FKMarqueeLabelExampleEnvironmentViewController() }
      ),
      DemoItem(
        title: "Background pause",
        subtitle: "DisplayLink stops on didEnterBackground; resumes on foreground.",
        factory: { FKMarqueeLabelExampleBackgroundPauseViewController() }
      ),
      DemoItem(
        title: "Accessibility",
        subtitle: "customLabel and optional updatesFrequently trait while scrolling.",
        factory: { FKMarqueeLabelExampleAccessibilityViewController() }
      ),
      DemoItem(
        title: "SwiftUI bridge",
        subtitle: "FKMarqueeLabelRepresentable with text, configuration, and isPaused binding.",
        factory: { FKMarqueeLabelExampleSwiftUIViewController() }
      ),
    ]),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Marquee"
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
