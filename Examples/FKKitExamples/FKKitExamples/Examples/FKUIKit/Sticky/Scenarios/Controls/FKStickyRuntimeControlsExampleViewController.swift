import FKUIKit
import UIKit

/// Enable/disable, force stick, per-target toggle, remove, and reset.
final class FKStickyRuntimeControlsExampleViewController: FKStickyExampleScrollPageViewController {
  private let stripA = FKStickyExampleUI.makeStrip(title: "Primary", backgroundColor: .systemBlue)
  private let stripB = FKStickyExampleUI.makeStrip(title: "Secondary", backgroundColor: .systemGreen)
  private var secondaryEnabled = true

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Runtime Controls"
    addIntro(
      title: "Engine & target controls",
      body: "Exercise setEnabled, forceStick / clearForcedStick, target.isEnabled, removeTarget, removeAllTargets, and reset."
    )

    addStickyStrip(stripA)
    addFillerBlocks(count: 6)
    addStickyStrip(stripB)
    addFillerBlocks(count: 12)

    var configuration = FKStickyConfiguration.default
    configuration.collisionBehavior = .stack
    let engine = scrollView.fk_stickyEngine
    engine.configuration = configuration
    engine.addTarget(id: "primary", view: stripA)
    engine.addTarget(id: "secondary", view: stripB)
    engine.onStuckTargetsChange = { [weak self] ids in
      self?.updateStatus("stuck=\(ids) enabled=\(engine.configuration.isEnabled) forced=\(engine.forcedTargetID ?? "nil")")
    }

    addActions([
      FKStickyExampleUI.makeButton("Toggle engine enabled") { [weak self] in
        guard let self else { return }
        let engine = self.scrollView.fk_stickyEngine
        engine.setEnabled(!engine.configuration.isEnabled)
        self.updateStatus("isEnabled=\(engine.configuration.isEnabled)")
      },
      FKStickyExampleUI.makeButton("Force stick primary") { [weak self] in
        self?.scrollView.fk_stickyEngine.forceStick(id: "primary")
      },
      FKStickyExampleUI.makeButton("Clear forced stick") { [weak self] in
        self?.scrollView.fk_stickyEngine.clearForcedStick()
      },
      FKStickyExampleUI.makeButton("Toggle secondary.isEnabled") { [weak self] in
        guard let self else { return }
        self.secondaryEnabled.toggle()
        self.scrollView.fk_stickyEngine.target(id: "secondary")?.isEnabled = self.secondaryEnabled
        self.scrollView.fk_reloadStickyLayout()
        self.updateStatus("secondary.isEnabled=\(self.secondaryEnabled)")
      },
      FKStickyExampleUI.makeButton("Remove secondary") { [weak self] in
        self?.scrollView.fk_stickyEngine.removeTarget(id: "secondary")
        self?.updateStatus("removed secondary")
      },
      FKStickyExampleUI.makeButton("Reset (keep observing)") { [weak self] in
        self?.scrollView.fk_resetSticky(stopObserving: false)
        self?.updateStatus("reset")
      },
      FKStickyExampleUI.makeButton("Remove all targets") { [weak self] in
        self?.scrollView.fk_stickyEngine.removeAllTargets()
        self?.updateStatus("removeAllTargets")
      },
    ])
  }
}
