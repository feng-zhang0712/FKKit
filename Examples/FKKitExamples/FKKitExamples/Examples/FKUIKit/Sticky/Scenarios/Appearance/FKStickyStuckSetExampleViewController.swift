import FKUIKit
import UIKit

/// Stuck-set observation and per-target query APIs.
final class FKStickyStuckSetExampleViewController: FKStickyExampleScrollPageViewController {
  private let stripA = FKStickyExampleUI.makeStrip(title: "Alpha", backgroundColor: .systemBlue)
  private let stripB = FKStickyExampleUI.makeStrip(title: "Beta", backgroundColor: .systemGreen)
  private let queryLabel = FKStickyExampleUI.caption("Queries appear here")

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Stuck Set"
    addIntro(
      title: "stuckTargetIDs & queries",
      body: "onStuckTargetsChange fires when the active set changes. Buttons read progress/state/target(id:)."
    )
    queryLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    queryLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(queryLabel)
    NSLayoutConstraint.activate([
      queryLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      queryLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      queryLabel.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: -4),
    ])

    addStickyStrip(stripA)
    addFillerBlocks(count: 7)
    addStickyStrip(stripB)
    addFillerBlocks(count: 12)

    var configuration = FKStickyConfiguration.default
    configuration.collisionBehavior = .stack
    let engine = scrollView.fk_stickyEngine
    engine.configuration = configuration
    engine.addTarget(id: "alpha", view: stripA)
    engine.addTarget(id: "beta", view: stripB)
    engine.onStuckTargetsChange = { [weak self] ids in
      self?.updateStatus("onStuckTargetsChange → [\(ids.joined(separator: ", "))]")
    }

    addActions([
      FKStickyExampleUI.makeButton("Refresh queries") { [weak self] in self?.refreshQueries() },
    ])
  }

  private func refreshQueries() {
    let engine = scrollView.fk_stickyEngine
    let alpha = engine.progress(for: "alpha")
    let betaState = engine.state(for: "beta")
    let targetTitle = engine.target(id: "alpha")?.view is FKStickyExampleStripView ? "alpha.view=strip" : "alpha.view=?"
    queryLabel.text = """
    stuckTargetIDs: \(engine.stuckTargetIDs)
    progress(alpha): \(alpha?.state.rawValue ?? "nil") \(alpha.map { String(format: "%.2f", $0.value) } ?? "-")
    state(beta): \(betaState?.rawValue ?? "nil")
    target(alpha): \(targetTitle)
    """
  }
}
