import FKCompositeKit
import UIKit

/// Hosts a single ``FKFilterTwoColumnListViewController`` plus a small event log.
final class FKFilterTwoColumnListShowcaseDetailViewController: UIViewController {

  private let scenario: FKFilterTwoColumnListShowcaseScenario
  private let logView = UITextView()
  private let panelContainer = UIView()
  private var panel: FKFilterTwoColumnListViewController?

  init(scenario: FKFilterTwoColumnListShowcaseScenario) {
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
    logView.isScrollEnabled = true
    logView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    logView.backgroundColor = .secondarySystemBackground
    logView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    logView.text = "Event log (newest at bottom).\n"

    panelContainer.translatesAutoresizingMaskIntoConstraints = false
    panelContainer.backgroundColor = .clear

    view.addSubview(logView)
    view.addSubview(panelContainer)

    NSLayoutConstraint.activate([
      logView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      logView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
      logView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
      logView.heightAnchor.constraint(equalToConstant: 120),

      panelContainer.topAnchor.constraint(equalTo: logView.bottomAnchor, constant: 8),
      panelContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      panelContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      panelContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    installPanel()
  }

  private func installPanel() {
    let spec = scenario.makeSpec()
    let panelVC = FKFilterTwoColumnListViewController(
      model: spec.model,
      configuration: spec.configuration,
      onChange: { [weak self] _ in
        self?.appendLog("onChange(_:)")
      },
      onSelection: spec.deliversSelectionEvents
        ? { [weak self] selection in
            let section = selection.sectionID?.rawValue ?? "nil"
            let mode = String(describing: selection.effectiveSelectionMode)
            self?.appendLog(
              "onSelection sectionID=\(section) itemID=\(selection.item.id.rawValue) title=\"\(selection.item.title)\" mode=\(mode)"
            )
          }
        : nil,
      allowsMultipleSelection: spec.allowsMultipleSelection
    )
    addChild(panelVC)
    panelVC.view.translatesAutoresizingMaskIntoConstraints = false
    panelContainer.addSubview(panelVC.view)
    NSLayoutConstraint.activate([
      panelVC.view.topAnchor.constraint(equalTo: panelContainer.topAnchor),
      panelVC.view.leadingAnchor.constraint(equalTo: panelContainer.leadingAnchor),
      panelVC.view.trailingAnchor.constraint(equalTo: panelContainer.trailingAnchor),
      panelVC.view.bottomAnchor.constraint(equalTo: panelContainer.bottomAnchor),
    ])
    panelVC.didMove(toParent: self)
    panel = panelVC
  }

  private func appendLog(_ line: String) {
    logView.text += line + "\n"
    let nsText = logView.text as NSString
    logView.scrollRangeToVisible(NSRange(location: max(0, nsText.length - 1), length: 1))
  }
}
