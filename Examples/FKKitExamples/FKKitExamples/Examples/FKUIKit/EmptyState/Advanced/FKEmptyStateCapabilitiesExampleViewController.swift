import FKCoreKit
import FKUIKit
import UIKit

/// Demonstrates density scaling, horizontal axis layout, tinted illustrations, and link actions.
final class FKEmptyStateCapabilitiesExampleViewController: UIViewController {
  private let container = UIView()
  private let modeControl = UISegmentedControl(items: ["Vertical", "Horizontal", "Compact"])

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Layout & Actions"
    view.backgroundColor = .systemBackground
    buildUI()
    render(mode: 0)
  }

  private func buildUI() {
    modeControl.selectedSegmentIndex = 0
    modeControl.translatesAutoresizingMaskIntoConstraints = false
    modeControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)

    container.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(modeControl)
    view.addSubview(container)
    NSLayoutConstraint.activate([
      modeControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      modeControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      modeControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      container.topAnchor.constraint(equalTo: modeControl.bottomAnchor, constant: 12),
      container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  @objc private func modeChanged() {
    render(mode: modeControl.selectedSegmentIndex)
  }

  private func render(mode: Int) {
    var model = FKEmptyStateConfiguration.scenario(.noFavorites)
    model.imageTintColor = .systemIndigo
    model.imageAccessibilityLabel = "Empty favorites illustration"
    model.actions = FKEmptyStateActionSet(
      primary: FKEmptyStateAction(id: "browse", title: "Browse catalog", kind: .primary),
      tertiary: FKEmptyStateAction(id: "learn", title: "Learn how favorites work", kind: .link)
    )
    model.isButtonHidden = false

    switch mode {
    case 1:
      model.axis = .horizontal
      model.maxContentWidth = 420
    case 2:
      model.density = .compact
      model.imageSize = CGSize(width: 40, height: 40)
    default:
      break
    }

    container.fk_applyEmptyState(model) { [weak self] action in
      self?.fk_presentMessageAlert(title: "Action", message: "Tapped action id: \(action.id)")
    }
  }
}
