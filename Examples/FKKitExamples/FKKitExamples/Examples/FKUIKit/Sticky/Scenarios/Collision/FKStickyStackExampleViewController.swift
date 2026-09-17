import FKUIKit
import UIKit

/// Multi-target stacked pins.
final class FKStickyStackExampleViewController: FKStickyExampleScrollPageViewController {
  private let filters = FKStickyExampleUI.makeStrip(title: "Filters", backgroundColor: .systemBlue, height: 44)
  private let tabs = FKStickyExampleUI.makeStrip(title: "Tabs", backgroundColor: .systemIndigo, height: 44)

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Stack"
    addIntro(
      title: "CollisionBehavior.stack",
      body: "Both strips remain stuck and stack under the pin line (filter + tabs). allowsPushOff = false maps to stack."
    )

    contentStack.addArrangedSubview(filters)
    addFillerBlocks(count: 6)
    contentStack.addArrangedSubview(tabs)
    addFillerBlocks(count: 16)

    var configuration = FKStickyConfiguration.default
    configuration.collisionBehavior = .stack
    let engine = scrollView.fk_stickyEngine
    engine.configuration = configuration

    engine.addTarget(id: "filters", view: filters)
    engine.addTarget(id: "tabs", view: tabs)
    engine.onStuckTargetsChange = { [weak self] ids in
      self?.updateStatus("stuck: [\(ids.joined(separator: ", "))]")
    }
  }
}
