import FKCoreKit
import FKUIKit
import UIKit

/// Demonstrates all action button chrome (primary / secondary / tertiary / link) and every ``FKEmptyStateTransition``.
final class FKEmptyStateActionsAndTransitionsExampleViewController: UIViewController {
  private let container = UIView()
  private let transitionControl = UISegmentedControl(items: ["None", "Cross", "Fade", "Scale", "Slide"])
  private let tertiaryStyleControl = UISegmentedControl(items: ["Plain", "Link"])
  private let replayButton = UIButton(type: .system)
  private let hintLabel = UILabel()
  private var usesAlternateCopy = false

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Actions & Transitions"
    view.backgroundColor = .systemBackground
    buildUI()
    applyEmptyState(animated: false)
  }

  private func buildUI() {
    transitionControl.selectedSegmentIndex = 0
    transitionControl.translatesAutoresizingMaskIntoConstraints = false
    transitionControl.addTarget(self, action: #selector(transitionChanged), for: .valueChanged)

    tertiaryStyleControl.selectedSegmentIndex = 0
    tertiaryStyleControl.translatesAutoresizingMaskIntoConstraints = false
    tertiaryStyleControl.addTarget(self, action: #selector(tertiaryStyleChanged), for: .valueChanged)

    replayButton.translatesAutoresizingMaskIntoConstraints = false
    replayButton.setTitle("Replay content transition", for: .normal)
    replayButton.addTarget(self, action: #selector(replayTransition), for: .touchUpInside)

    hintLabel.translatesAutoresizingMaskIntoConstraints = false
    hintLabel.font = .preferredFont(forTextStyle: .footnote)
    hintLabel.textColor = .secondaryLabel
    hintLabel.numberOfLines = 0
    hintLabel.text =
      "Primary/secondary styles come from appearance.buttons. Plain vs Link toggles tertiary chrome. Changing the transition segment or tapping Replay previews the selected animation."

    container.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(transitionControl)
    view.addSubview(tertiaryStyleControl)
    view.addSubview(replayButton)
    view.addSubview(hintLabel)
    view.addSubview(container)

    NSLayoutConstraint.activate([
      transitionControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      transitionControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      transitionControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

      tertiaryStyleControl.topAnchor.constraint(equalTo: transitionControl.bottomAnchor, constant: 10),
      tertiaryStyleControl.leadingAnchor.constraint(equalTo: transitionControl.leadingAnchor),
      tertiaryStyleControl.trailingAnchor.constraint(equalTo: transitionControl.trailingAnchor),

      replayButton.topAnchor.constraint(equalTo: tertiaryStyleControl.bottomAnchor, constant: 10),
      replayButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

      hintLabel.topAnchor.constraint(equalTo: replayButton.bottomAnchor, constant: 8),
      hintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      hintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

      container.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 8),
      container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  @objc private func transitionChanged() {
    previewTransition()
  }

  @objc private func tertiaryStyleChanged() {
    applyEmptyState(animated: false)
  }

  @objc private func replayTransition() {
    previewTransition()
  }

  private func previewTransition() {
    usesAlternateCopy.toggle()
    applyEmptyState(animated: selectedTransition() != .none)
  }

  private func applyEmptyState(animated: Bool) {
    var model = makeModel()
    model.presentation.transition = selectedTransition()
    container.fk_updateVisibleEmptyState(model, animated: animated) { [weak self] action in
      self?.fk_presentMessageAlert(
        title: "Action",
        message: "Tapped \(action.kind.rawValue) action (id: \(action.id))."
      )
    }
  }

  private func selectedTransition() -> FKEmptyStateTransition {
    switch transitionControl.selectedSegmentIndex {
    case 1: return .crossDissolve
    case 2: return .fade
    case 3: return .scale
    case 4: return .slideUp
    default: return .none
    }
  }

  private func makeModel() -> FKEmptyStateConfiguration {
    var model = FKEmptyStateConfiguration.scenario(.noFavorites)
    model.layout.context = .section
    model.presentation.fadeDuration = 0.45

    model.appearance.buttons.primary = FKEmptyStateButtonStyle(
      titleColor: .white,
      font: .systemFont(ofSize: 15, weight: .semibold),
      backgroundColor: .systemBlue,
      cornerRadius: 12,
      contentInsets: UIEdgeInsets(top: 11, left: 18, bottom: 11, right: 18)
    )
    model.appearance.buttons.secondary = FKEmptyStateButtonStyle(
      titleColor: .systemBlue,
      font: .systemFont(ofSize: 15, weight: .medium),
      backgroundColor: .clear,
      cornerRadius: 10,
      contentInsets: UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16),
      borderColor: .systemBlue,
      borderWidth: 1
    )

    let tertiaryAction: FKEmptyStateAction
    if tertiaryStyleControl.selectedSegmentIndex == 1 {
      model.appearance.buttons.tertiary = FKEmptyStateButtonStyle(
        titleColor: .systemBlue,
        font: .systemFont(ofSize: 15, weight: .regular),
        backgroundColor: .clear,
        cornerRadius: 0,
        contentInsets: UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
      )
      tertiaryAction = FKEmptyStateAction(id: "learn", title: "Learn how favorites work", kind: .link)
    } else {
      model.appearance.buttons.tertiary = FKEmptyStateButtonStyle(
        titleColor: .secondaryLabel,
        font: .systemFont(ofSize: 15, weight: .regular),
        backgroundColor: .clear,
        cornerRadius: 0,
        contentInsets: UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
      )
      tertiaryAction = FKEmptyStateAction(id: "skip", title: "Skip for now", kind: .tertiary)
    }

    model.actions = FKEmptyStateActionSet(
      primary: FKEmptyStateAction(id: "browse", title: "Browse catalog", kind: .primary),
      secondary: FKEmptyStateAction(id: "create", title: "Create item", kind: .secondary),
      tertiary: tertiaryAction
    )

    let symbolConfig = UIImage.SymbolConfiguration(pointSize: 44, weight: .medium)
    if usesAlternateCopy {
      model.content.title = "Nothing here yet"
      model.content.description = "Pull to refresh or tap Browse catalog to load items."
      model.content.image = FKEmptyStateImageContent(
        image: UIImage(systemName: "tray", withConfiguration: symbolConfig) ?? UIImage(),
        tintColor: .systemOrange
      )
    } else {
      model.content.image = FKEmptyStateImageContent(
        image: UIImage(systemName: "heart.slash", withConfiguration: symbolConfig) ?? UIImage(),
        tintColor: .systemBlue
      )
    }

    return model
  }
}
