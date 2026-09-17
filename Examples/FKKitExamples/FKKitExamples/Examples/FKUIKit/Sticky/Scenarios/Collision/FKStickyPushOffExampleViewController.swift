import FKUIKit
import UIKit

/// Multi-target push-off collision.
final class FKStickyPushOffExampleViewController: FKStickyExampleScrollPageViewController {
  private let stripA = FKStickyExampleUI.makeStrip(title: "Section A", backgroundColor: .systemBlue)
  private let stripB = FKStickyExampleUI.makeStrip(title: "Section B", backgroundColor: .systemGreen)
  private let stripC = FKStickyExampleUI.makeStrip(title: "Section C", backgroundColor: .systemPink)

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Push-Off"
    addIntro(
      title: "CollisionBehavior.pushOff",
      body: "Default multi-target mode. The next section bar pushes the previous one off the pin line."
    )

    contentStack.addArrangedSubview(stripA)
    addFillerBlocks(count: 8)
    contentStack.addArrangedSubview(stripB)
    addFillerBlocks(count: 8)
    contentStack.addArrangedSubview(stripC)
    addFillerBlocks(count: 10)

    var configuration = FKStickyConfiguration.default
    configuration.collisionBehavior = .pushOff
    let engine = scrollView.fk_stickyEngine
    engine.configuration = configuration

    for (id, strip) in [("a", stripA), ("b", stripB), ("c", stripC)] {
      engine.addTarget(id: id, view: strip) { [weak self, weak engine] _ in
        guard let self, let engine else { return }
        self.updateStatus(engine.stuckTargetIDs.map { self.progressLine(for: engine, id: $0) }.joined(separator: " | "))
      }
    }
  }
}
