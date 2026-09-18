import FKUIKit
import UIKit

/// Placeholder off, hysteresis, priority ties, and per-target inset override.
final class FKStickyConfigurationDetailsExampleViewController: FKStickyExampleScrollPageViewController {
  private let stripLow = FKStickyExampleUI.makeStrip(title: "Priority 0 (same Y)", backgroundColor: .systemGray)
  private let stripHigh = FKStickyExampleUI.makeStrip(title: "Priority 10 + insetOverride", backgroundColor: .systemRed)
  private let stripSolo = FKStickyExampleUI.makeStrip(title: "Hysteresis / no placeholder", backgroundColor: .systemBlue)

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Config Details"
    addIntro(
      title: "Advanced configuration knobs",
      body: "1) Two strips share a Y via a side-by-side row — higher priority wins. 2) stickyInsetOverride on the red strip. 3) Solo strip toggles preservesPlaceholder and unstickHysteresis."
    )

    let row = UIStackView(arrangedSubviews: [stripLow, stripHigh])
    row.axis = .horizontal
    row.spacing = 8
    row.distribution = .fillEqually
    contentStack.addArrangedSubview(row)
    addFillerBlocks(count: 8)
    addStickyStrip(stripSolo)
    addFillerBlocks(count: 12)

    var configuration = FKStickyConfiguration.default
    configuration.collisionBehavior = .pushOff
    configuration.preservesPlaceholder = true
    configuration.unstickHysteresis = 12
    configuration.transitionDistance = 16
    let engine = scrollView.fk_stickyEngine
    engine.configuration = configuration

    engine.addTarget(id: "low", view: stripLow, priority: 0)
    engine.addTarget(id: "high", view: stripHigh, priority: 10, stickyInsetOverride: 8)
    engine.addTarget(id: "solo", view: stripSolo) { [weak self] progress in
      self?.updateStatus("solo → \(progress.state.rawValue) hyst=\(Int(engine.configuration.unstickHysteresis)) placeholder=\(engine.configuration.preservesPlaceholder)")
    }

    addActions([
      FKStickyExampleUI.makeButton("Toggle preservesPlaceholder") { [weak self] in
        guard let self else { return }
        var config = self.scrollView.fk_stickyEngine.configuration
        config.preservesPlaceholder.toggle()
        self.scrollView.fk_stickyEngine.configuration = config
        self.updateStatus("preservesPlaceholder=\(config.preservesPlaceholder)")
      },
      FKStickyExampleUI.makeButton("Hysteresis 0 ↔ 24") { [weak self] in
        guard let self else { return }
        var config = self.scrollView.fk_stickyEngine.configuration
        config.unstickHysteresis = config.unstickHysteresis < 1 ? 24 : 0
        self.scrollView.fk_stickyEngine.configuration = config
        self.updateStatus("unstickHysteresis=\(Int(config.unstickHysteresis))")
      },
    ])
  }
}
