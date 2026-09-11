import UIKit
import FKUIKit

/// Pins a composer bar with ``FKKeyboardLayout``.
final class FKKeyboardLayoutGuideExampleViewController: UIViewController {
  private let scrollView = UIScrollView()
  private let stack = FKKeyboardExampleUI.cardStack()
  private let composer = UIView()
  private let field = FKKeyboardExampleUI.makeTextField(placeholder: "Composer pinned to keyboardLayoutGuide")
  private var dismissController: FKKeyboardDismissController?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Layout guide"
    view.backgroundColor = .systemGroupedBackground
    dismissController = FKKeyboardExampleUI.installTapToDismiss(on: view)

    scrollView.translatesAutoresizingMaskIntoConstraints = false
    composer.translatesAutoresizingMaskIntoConstraints = false
    composer.backgroundColor = .secondarySystemBackground

    let intro = FKKeyboardExampleUI.caption(
      "FKKeyboardLayout.pinBottom pins the composer to host.keyboardLayoutGuide.topAnchor. The scroll view bottom is also pinned above the composer."
    )
    stack.addArrangedSubview(FKKeyboardExampleUI.headline("Preferred Auto Layout path"))
    stack.addArrangedSubview(intro)
    for index in 1...12 {
      stack.addArrangedSubview(FKKeyboardExampleUI.caption("Feed row \(index)"))
    }

    let composerStack = FKKeyboardExampleUI.cardStack()
    composerStack.addArrangedSubview(field)
    composer.addSubview(composerStack)

    view.addSubview(scrollView)
    scrollView.addSubview(stack)
    view.addSubview(composer)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

      stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
      stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),

      composer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      composer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

      composerStack.topAnchor.constraint(equalTo: composer.topAnchor, constant: 10),
      composerStack.leadingAnchor.constraint(equalTo: composer.leadingAnchor, constant: 16),
      composerStack.trailingAnchor.constraint(equalTo: composer.trailingAnchor, constant: -16),
      composerStack.bottomAnchor.constraint(equalTo: composer.bottomAnchor, constant: -10),
    ])

    let composerTop = scrollView.bottomAnchor.constraint(equalTo: composer.topAnchor)
    composerTop.isActive = true
    FKKeyboardLayout.pinBottom(of: composer, toKeyboardTopOf: view)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    dismissController?.stop()
  }
}
