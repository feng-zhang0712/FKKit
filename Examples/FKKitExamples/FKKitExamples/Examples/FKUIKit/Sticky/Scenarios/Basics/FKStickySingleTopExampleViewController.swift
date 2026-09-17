import FKUIKit
import UIKit

/// Baseline: one top-edge sticky strip on a plain UIScrollView.
final class FKStickySingleTopExampleViewController: FKStickyExampleScrollPageViewController {
  private let strip = FKStickyExampleUI.makeStrip(title: "Filters", backgroundColor: .systemBlue)

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Single Top"
    addIntro(
      title: "Default top sticky",
      body: "Uses scrollView.fk_addStickyTarget with default FKStickyConfiguration (top edge, automatic KVO)."
    )
    contentStack.addArrangedSubview(strip)
    addFillerBlocks()

    let target = scrollView.fk_addStickyTarget(id: "filters", view: strip) { [weak self] progress in
      self?.updateStatus("filters → \(progress.state.rawValue)  progress=\(String(format: "%.2f", progress.value))")
    }
    target.onDidStick = { [weak self] in self?.updateStatus("didStick: filters") }
    target.onDidUnstick = { [weak self] in self?.updateStatus("didUnstick: filters") }
  }
}
