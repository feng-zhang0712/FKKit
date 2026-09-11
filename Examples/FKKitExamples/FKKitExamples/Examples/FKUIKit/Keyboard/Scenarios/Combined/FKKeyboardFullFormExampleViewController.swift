import UIKit
import FKUIKit

/// Combines avoidance, focus scrolling, toolbar, dismiss, and layout-guide pinning.
final class FKKeyboardFullFormExampleViewController: UIViewController, UITextFieldDelegate {
  private let scrollView = UIScrollView()
  private let stack = FKKeyboardExampleUI.cardStack()
  private let footer = UIView()
  private let submit = UIButton(type: .system)

  private let navigator = FKKeyboardFormNavigator()
  private let toolbar = FKKeyboardToolbar()
  private var avoidance: FKKeyboardAvoidanceController?
  private var dismissController: FKKeyboardDismissController?

  private lazy var fields: [UITextField] = [
    FKKeyboardExampleUI.makeTextField(placeholder: "Full name"),
    FKKeyboardExampleUI.makeTextField(placeholder: "Email", keyboardType: .emailAddress),
    FKKeyboardExampleUI.makeTextField(placeholder: "Phone", keyboardType: .phonePad),
    FKKeyboardExampleUI.makeTextField(placeholder: "Company"),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Full form recipe"
    view.backgroundColor = .systemGroupedBackground

    scrollView.translatesAutoresizingMaskIntoConstraints = false
    footer.translatesAutoresizingMaskIntoConstraints = false
    footer.backgroundColor = .secondarySystemBackground
    submit.setTitle("Submit", for: .normal)
    submit.titleLabel?.font = .preferredFont(forTextStyle: .headline)

    stack.addArrangedSubview(FKKeyboardExampleUI.headline("Everything together"))
    stack.addArrangedSubview(FKKeyboardExampleUI.caption(
      "Avoidance (IQ-style focus align) + toolbar/navigator + tap dismiss + footer pinned with FKKeyboardLayout."
    ))
    for (index, field) in fields.enumerated() {
      field.delegate = self
      field.returnKeyType = index == fields.count - 1 ? .done : .next
      let label = UILabel()
      label.text = "Field \(index + 1)"
      label.font = .preferredFont(forTextStyle: .subheadline)
      label.textColor = .secondaryLabel
      stack.addArrangedSubview(label)
      stack.addArrangedSubview(field)
    }

    let footerStack = FKKeyboardExampleUI.cardStack()
    footerStack.addArrangedSubview(submit)
    footer.addSubview(footerStack)

    view.addSubview(scrollView)
    scrollView.addSubview(stack)
    view.addSubview(footer)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

      stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
      stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),

      footer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      footer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: footer.topAnchor),

      footerStack.topAnchor.constraint(equalTo: footer.topAnchor, constant: 10),
      footerStack.leadingAnchor.constraint(equalTo: footer.leadingAnchor, constant: 16),
      footerStack.trailingAnchor.constraint(equalTo: footer.trailingAnchor, constant: -16),
      footerStack.bottomAnchor.constraint(equalTo: footer.bottomAnchor, constant: -10),
    ])
    FKKeyboardLayout.pinBottom(of: footer, toKeyboardTopOf: view)

    navigator.fields = fields
    toolbar.install(asAccessoryOn: fields)
    toolbar.attach(to: navigator)

    let avoidanceController = FKKeyboardAvoidanceController(
      hostView: view,
      configuration: .init(
        strategy: .adjustContentInsets,
        additionalBottomInset: 4,
        keyboardDistanceFromFocusedView: 10
      )
    )
    avoidanceController.scrollView = scrollView
    avoidance = avoidanceController

    let dismiss = FKKeyboardDismissController(containerView: view)
    dismiss.start()
    dismissController = dismiss
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    avoidance?.start()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    avoidance?.stop()
    dismissController?.stop()
    navigator.stopFocusTracking()
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    _ = navigator.handleReturn(from: textField)
    return true
  }
}
