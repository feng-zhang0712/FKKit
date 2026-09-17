import FKUIKit
import UIKit

/// Progress callbacks, lifecycle hooks, and engine-applied stuck shadow.
final class FKStickyProgressLifecycleExampleViewController: FKStickyExampleScrollPageViewController {
  private let strip = FKStickyExampleUI.makeStrip(title: "Lifecycle strip", backgroundColor: .systemCyan)
  private let logLabel = FKStickyExampleUI.caption("")

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Progress & Lifecycle"
    addIntro(
      title: "Callbacks + appliesStuckShadow",
      body: "Watch progress, willStick / didStick / didUnstick. Engine shadow is applied while stuck."
    )
    // Keep the growing log outside scroll content so appends do not fight max contentOffset.
    logLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    logLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(logLabel)
    NSLayoutConstraint.activate([
      logLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      logLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      logLabel.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: -4),
    ])
    contentStack.addArrangedSubview(strip)
    addFillerBlocks()

    var configuration = FKStickyConfiguration.default
    configuration.appliesStuckShadow = true
    configuration.stuckShadowOpacity = 0.22
    configuration.transitionDistance = 24
    let engine = scrollView.fk_stickyEngine
    engine.configuration = configuration

    let target = engine.addTarget(id: "lifecycle", view: strip) { [weak self] progress in
      self?.updateStatus("progress=\(String(format: "%.2f", progress.value)) state=\(progress.state.rawValue)")
      self?.strip.alpha = 0.65 + 0.35 * progress.value
    }
    target.onWillStick = { [weak self] in self?.appendLog("onWillStick") }
    target.onDidStick = { [weak self] in self?.appendLog("onDidStick") }
    target.onDidUnstick = { [weak self] in self?.appendLog("onDidUnstick") }
  }

  private func appendLog(_ line: String) {
    let stamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
    let next = "[\(stamp)] \(line)"
    if let existing = logLabel.text, !existing.isEmpty {
      logLabel.text = existing + "\n" + next
    } else {
      logLabel.text = next
    }
  }
}
