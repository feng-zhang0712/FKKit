import UIKit
import FKUIKit

/// Shared layout helpers for Keyboard demos.
enum FKKeyboardExampleUI {
  static func makeTextField(placeholder: String, keyboardType: UIKeyboardType = .default) -> UITextField {
    let field = UITextField()
    field.placeholder = placeholder
    field.borderStyle = .roundedRect
    field.keyboardType = keyboardType
    field.autocorrectionType = .no
    field.translatesAutoresizingMaskIntoConstraints = false
    field.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
    return field
  }

  static func makeTextView(placeholderHint: String) -> UITextView {
    let view = UITextView()
    view.font = .preferredFont(forTextStyle: .body)
    view.layer.cornerRadius = 8
    view.layer.borderWidth = 1 / UIScreen.main.scale
    view.layer.borderColor = UIColor.separator.cgColor
    view.translatesAutoresizingMaskIntoConstraints = false
    view.heightAnchor.constraint(equalToConstant: 120).isActive = true
    view.accessibilityHint = placeholderHint
    return view
  }

  static func caption(_ text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    return label
  }

  static func headline(_ text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = .preferredFont(forTextStyle: .headline)
    label.numberOfLines = 0
    return label
  }

  static func monospaceLabel() -> UILabel {
    let label = UILabel()
    label.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    label.textColor = .label
    label.numberOfLines = 0
    return label
  }

  static func cardStack() -> UIStackView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false
    return stack
  }

  /// Installs tap-to-dismiss on `host` and returns the controller (caller should retain + stop).
  @discardableResult
  static func installTapToDismiss(on host: UIView) -> FKKeyboardDismissController {
    let controller = FKKeyboardDismissController(containerView: host)
    controller.start()
    return controller
  }
}

/// Scrollable demo page with a vertical content stack and tap-to-dismiss keyboard.
class FKKeyboardExamplePageViewController: UIViewController {
  let scrollView = UIScrollView()
  let contentStack = FKKeyboardExampleUI.cardStack()

  /// When `true` (default), taps outside text inputs dismiss the keyboard.
  /// Override in demos that manage their own ``FKKeyboardDismissController``.
  var installsTapToDismissKeyboard: Bool { true }

  private var pageDismissController: FKKeyboardDismissController?

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.keyboardDismissMode = .interactive
    view.addSubview(scrollView)
    scrollView.addSubview(contentStack)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
      contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
      contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
      contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32),
    ])

    if installsTapToDismissKeyboard {
      pageDismissController = FKKeyboardExampleUI.installTapToDismiss(on: view)
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    pageDismissController?.stop()
  }

  func addIntro(title: String, body: String) {
    contentStack.addArrangedSubview(FKKeyboardExampleUI.headline(title))
    contentStack.addArrangedSubview(FKKeyboardExampleUI.caption(body))
  }

  func addField(title: String, field: UIView) {
    let row = UIStackView()
    row.axis = .vertical
    row.spacing = 6
    let label = UILabel()
    label.text = title
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.textColor = .secondaryLabel
    row.addArrangedSubview(label)
    row.addArrangedSubview(field)
    contentStack.addArrangedSubview(row)
  }

  /// Adds spacer views so lower fields sit near the bottom of a tall form.
  func addTallSpacer(multiplicity: Int = 8) {
    for index in 1...multiplicity {
      let spacer = FKKeyboardExampleUI.caption("Scroll padding \(index)")
      spacer.textAlignment = .center
      contentStack.addArrangedSubview(spacer)
    }
  }
}
