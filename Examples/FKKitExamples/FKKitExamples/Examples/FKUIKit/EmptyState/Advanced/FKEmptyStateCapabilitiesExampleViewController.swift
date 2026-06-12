import FKCoreKit
import FKUIKit
import UIKit

/// Demonstrates density scaling, horizontal axis layout, segment spacing, capsule buttons, and link actions.
final class FKEmptyStateCapabilitiesExampleViewController: UIViewController {
  private let container = UIView()
  private let modeControl = UISegmentedControl(items: ["Vertical", "Horizontal", "Compact", "Segment spacing"])

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
    model.content.image?.tintColor = .systemIndigo
    model.content.image?.accessibilityLabel = "Empty favorites illustration"
    model.actions = FKEmptyStateActionSet(
      primary: FKEmptyStateAction(id: "browse", title: "Browse catalog", kind: .primary),
      tertiary: FKEmptyStateAction(id: "learn", title: "Learn how favorites work", kind: .link)
    )
    model.appearance.buttons.primary.cornerStyle = .capsule

    switch mode {
    case 1:
      model.layout.axis = .horizontal
      model.layout.maxContentWidth = 420
    case 2:
      model.layout.density = .compact
      model.layout.imageSize = CGSize(width: 40, height: 40)
    case 3:
      model.layout.segmentSpacing.afterImage = 24
      model.layout.segmentSpacing.afterTitle = 4
      model.layout.segmentSpacing.afterDescription = 28
      model.layout.verticalSpacing = 10
    default:
      break
    }

    container.fk_applyEmptyState(model) { [weak self] action in
      self?.fk_presentMessageAlert(title: "Action", message: "Tapped action id: \(action.id)")
    }
  }
}
