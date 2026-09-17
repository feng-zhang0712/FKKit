import FKUIKit
import UIKit

/// Remeasures a stuck strip after a height change via reloadLayout.
final class FKStickyReloadLayoutExampleViewController: FKStickyExampleScrollPageViewController {
  private let strip = FKStickyExampleUI.makeStrip(title: "Resizable strip", backgroundColor: .systemMint, height: 48)
  private var tall = false
  private var heightConstraint: NSLayoutConstraint?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Reload Layout"
    addIntro(
      title: "reloadLayout while stuck",
      body: "Pin the strip, then toggle its height. fk_reloadStickyLayout updates natural size and placeholder without unsticking."
    )

    // Replace the default height constraint reference.
    strip.constraints.filter { $0.firstAttribute == .height }.forEach { strip.removeConstraint($0) }
    let height = strip.heightAnchor.constraint(equalToConstant: 48)
    height.isActive = true
    heightConstraint = height

    contentStack.addArrangedSubview(strip)
    addFillerBlocks()

    scrollView.fk_addStickyTarget(id: "resizable", view: strip) { [weak self] progress in
      self?.updateStatus("resizable → \(progress.state.rawValue) h=\(Int(self?.heightConstraint?.constant ?? 0))")
    }

    addActions([
      FKStickyExampleUI.makeButton("Toggle height (48 ↔ 96) + reload") { [weak self] in
        self?.toggleHeight()
      },
    ])
  }

  private func toggleHeight() {
    tall.toggle()
    heightConstraint?.constant = tall ? 96 : 48
    strip.titleLabel.text = tall ? "Resizable strip (tall)" : "Resizable strip"
    UIView.animate(withDuration: 0.2) {
      self.view.layoutIfNeeded()
    } completion: { _ in
      self.scrollView.fk_reloadStickyLayout()
      let engine = self.scrollView.fk_stickyEngine
      self.updateStatus(
        "reloaded h=\(Int(self.heightConstraint?.constant ?? 0)) stuck=\(engine.stuckTargetIDs)"
      )
    }
  }
}
