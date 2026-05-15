import FKCompositeKit
import UIKit

final class FKFilterTwoColumnGridShowcaseDetailViewController: UIViewController {

  private let scenario: FKFilterTwoColumnGridShowcaseScenario
  private let logView = UITextView()
  private let panelContainer = UIView()

  init(scenario: FKFilterTwoColumnGridShowcaseScenario) {
    self.scenario = scenario
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    title = scenario.menuTitle

    logView.translatesAutoresizingMaskIntoConstraints = false
    logView.isEditable = false
    logView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    logView.backgroundColor = .secondarySystemBackground
    logView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    logView.text = "Event log.\n"

    panelContainer.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(logView)
    view.addSubview(panelContainer)

    NSLayoutConstraint.activate([
      logView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      logView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
      logView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
      logView.heightAnchor.constraint(equalToConstant: 110),

      panelContainer.topAnchor.constraint(equalTo: logView.bottomAnchor, constant: 8),
      panelContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      panelContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      panelContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    let spec = scenario.makeSpec()
    let panel = FKFilterTwoColumnGridViewController(
      model: spec.model,
      configuration: spec.configuration,
      onChange: { [weak self] _ in self?.appendLog("onChange(_:)") },
      onSelection: spec.deliversSelectionEvents
        ? { [weak self] sel in
            let sid = sel.sectionID?.rawValue ?? "nil"
            self?.appendLog(
              "onSelection sectionID=\(sid) item=\(sel.item.id.rawValue) mode=\(String(describing: sel.effectiveSelectionMode))"
            )
          }
        : nil,
      allowsMultipleSelection: spec.allowsMultipleSelection
    )
    addChild(panel)
    panel.view.translatesAutoresizingMaskIntoConstraints = false
    panelContainer.addSubview(panel.view)
    NSLayoutConstraint.activate([
      panel.view.topAnchor.constraint(equalTo: panelContainer.topAnchor),
      panel.view.leadingAnchor.constraint(equalTo: panelContainer.leadingAnchor),
      panel.view.trailingAnchor.constraint(equalTo: panelContainer.trailingAnchor),
      panel.view.bottomAnchor.constraint(equalTo: panelContainer.bottomAnchor),
    ])
    panel.didMove(toParent: self)
  }

  private func appendLog(_ line: String) {
    logView.text += line + "\n"
    let ns = logView.text as NSString
    logView.scrollRangeToVisible(NSRange(location: max(0, ns.length - 1), length: 1))
  }
}
