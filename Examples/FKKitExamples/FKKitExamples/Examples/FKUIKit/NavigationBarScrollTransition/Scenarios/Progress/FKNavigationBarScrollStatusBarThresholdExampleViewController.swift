import FKUIKit
import UIKit

/// Discrete status-bar flipping via discreteThreshold.
final class FKNavigationBarScrollStatusBarThresholdExampleViewController:
  FKNavigationBarScrollExampleHeroPageViewController
{
  override var heroTitle: String { "Status Bar" }
  private weak var engine: FKNavigationBarScrollEngine?
  private let thresholdLabel = FKNavigationBarScrollExampleUI.caption("threshold=0.50")

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Status"

    addIntro(
      title: "discreteThreshold",
      body: "Status-bar style flips at discreteThreshold (continuous fields still lerp). Toggle threshold and updatesStatusBarAppearance. preferredStatusBarStyle returns engine.resolvedStatusBarStyle."
    )

    let wrap = UIView()
    thresholdLabel.translatesAutoresizingMaskIntoConstraints = false
    wrap.addSubview(thresholdLabel)
    NSLayoutConstraint.activate([
      thresholdLabel.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 4),
      thresholdLabel.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -4),
      thresholdLabel.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 16),
      thresholdLabel.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -16),
    ])
    contentStack.addArrangedSubview(wrap)

    addActions([
      FKNavigationBarScrollExampleUI.makeButton("Threshold 0.25") { [weak self] in
        self?.setThreshold(0.25)
      },
      FKNavigationBarScrollExampleUI.makeButton("Threshold 0.50") { [weak self] in
        self?.setThreshold(0.50)
      },
      FKNavigationBarScrollExampleUI.makeButton("Threshold 0.80") { [weak self] in
        self?.setThreshold(0.80)
      },
      FKNavigationBarScrollExampleUI.makeButton("Toggle updatesStatusBarAppearance") { [weak self] in
        guard let self, let engine = self.engine else { return }
        var configuration = engine.configuration
        configuration.updatesStatusBarAppearance.toggle()
        engine.configuration = configuration
        self.thresholdLabel.text = String(
          format: "threshold=%.2f  updatesStatusBar=%@",
          configuration.discreteThreshold,
          configuration.updatesStatusBarAppearance ? "true" : "false"
        )
      },
    ])
    addFillerBlocks()

    engine = installDefaultEngine()
    refreshThresholdLabel()
  }

  private func setThreshold(_ value: CGFloat) {
    guard let engine else { return }
    var configuration = engine.configuration
    configuration.discreteThreshold = value
    engine.configuration = configuration
    engine.reload()
    cachedStatusBarStyle = engine.resolvedStatusBarStyle
    setNeedsStatusBarAppearanceUpdate()
    refreshThresholdLabel()
    updateStatus(from: engine)
  }

  private func refreshThresholdLabel() {
    guard let engine else { return }
    thresholdLabel.text = String(
      format: "threshold=%.2f  updatesStatusBar=%@  resolved=%@",
      engine.configuration.discreteThreshold,
      engine.configuration.updatesStatusBarAppearance ? "true" : "false",
      String(describing: engine.resolvedStatusBarStyle)
    )
  }
}
