import FKCompositeKit
import UIKit

/// Plain `UIViewController` using ``FKViewControllerComposite`` + ``FKViewControllerBuildPhases`` (no ``FKBaseViewController``).
final class FKBaseCompositionExampleViewController: UIViewController,
  FKViewControllerBuildPhases,
  FKViewControllerCompositeHosting,
  FKViewControllerTraitChangeHandling {

  let composite = FKViewControllerComposite()

  private let stack = UIStackView()
  private let field = UITextField()
  private let hint = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Composition"
    view.backgroundColor = .systemBackground
    forwardComposite(.viewDidLoad)
    runBuildPhases()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    forwardComposite(.viewWillAppear(animated: animated))
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    forwardComposite(.viewDidAppear(animated: animated))
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    forwardComposite(.viewWillDisappear(animated: animated))
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    forwardComposite(.viewDidDisappear)
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    handleTraitCollectionChange(previousTraitCollection)
  }

  func buildInterface() {
    composite.navigationChrome.visibility = .visible
    composite.navigationChrome.style = .system
    composite.tapToDismissKeyboard.isEnabled = true
    composite.disablesScrollBounceRecursivelyByDefault = false

    composite.keyboard.onWillChangeFrame = { [weak self] _, _, _ in
      self?.hint.text = "Keyboard visible (composite keyboard driver)."
    }
    composite.keyboard.onWillHide = { [weak self] _, _ in
      self?.hint.text = "Keyboard hidden. Uses same notification parsing as FKBaseViewController."
    }

    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false

    hint.numberOfLines = 0
    hint.font = .preferredFont(forTextStyle: .footnote)
    hint.textColor = .secondaryLabel
    hint.text = "This screen does not inherit FKBaseViewController. Composite handles keyboard + nav chrome + tap-to-dismiss."

    field.borderStyle = .roundedRect
    field.placeholder = "Focus to test keyboard forwarding"

    stack.addArrangedSubview(hint)
    stack.addArrangedSubview(field)

    let navButtons: [(String, () -> Void)] = [
      ("Transparent nav bar", { [weak self] in self?.composite.navigationChrome.style = .transparent }),
      ("Opaque nav bar", { [weak self] in self?.composite.navigationChrome.style = .opaqueDefault }),
      ("System (no override)", { [weak self] in self?.composite.navigationChrome.style = .system }),
    ]
    navButtons.forEach { title, action in
      let b = UIButton(type: .system)
      b.configuration = .bordered()
      b.configuration?.title = title
      b.addAction(UIAction { _ in action() }, for: .touchUpInside)
      stack.addArrangedSubview(b)
    }

    view.addSubview(stack)
  }

  func buildConstraints() {
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
    ])
  }

  func bindInteractions() {
    composite.appearanceState.onFirstAppearance = { [weak self] _ in
      self?.hint.text = "First appearance recorded by composite.appearanceState."
    }
  }

  func handleTraitCollectionChange(_ previousTraitCollection: UITraitCollection?) {
    view.setNeedsLayout()
  }
}
