import FKUIKit
import UIKit

/// Bottom-edge sticky strip.
final class FKStickyBottomEdgeExampleViewController: FKStickyExampleScrollPageViewController {
  private let strip = FKStickyExampleUI.makeStrip(title: "Composer chrome", backgroundColor: .systemPurple)

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Bottom Edge"
    addIntro(
      title: "FKStickyEdge.bottom",
      body: "Pins above adjustedContentInset.bottom. Scroll so the strip reaches the bottom pin line."
    )
    addFillerBlocks(count: 12)
    contentStack.addArrangedSubview(strip)
    addFillerBlocks(count: 8)

    var configuration = FKStickyConfiguration.default
    configuration.edge = .bottom
    scrollView.fk_stickyEngine.configuration = configuration
    scrollView.fk_addStickyTarget(id: "composer", view: strip) { [weak self] progress in
      self?.updateStatus("composer → \(progress.state.rawValue) p=\(String(format: "%.2f", progress.value))")
    }
  }
}
