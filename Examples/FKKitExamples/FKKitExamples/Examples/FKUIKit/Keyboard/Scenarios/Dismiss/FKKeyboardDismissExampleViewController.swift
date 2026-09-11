import UIKit
import FKUIKit

/// ``FKKeyboardDismissController`` with configuration toggles.
final class FKKeyboardDismissExampleViewController: FKKeyboardExamplePageViewController {
  override var installsTapToDismissKeyboard: Bool { false }

  private var dismissController: FKKeyboardDismissController?
  private let cancelsSwitch = UISwitch()
  private let ignoreSwitch = UISwitch()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Tap to dismiss"
    addIntro(
      title: "Tap outside to end editing",
      body: "Toggle cancelsTouchesInView and ignoresTapsInsideFirstResponder. Buttons below still work when cancelsTouches is off."
    )

    ignoreSwitch.isOn = true
    let row1 = makeToggleRow(title: "cancelsTouchesInView", control: cancelsSwitch)
    let row2 = makeToggleRow(title: "ignoresTapsInsideFirstResponder", control: ignoreSwitch)
    contentStack.addArrangedSubview(row1)
    contentStack.addArrangedSubview(row2)

    cancelsSwitch.addTarget(self, action: #selector(reinstall), for: .valueChanged)
    ignoreSwitch.addTarget(self, action: #selector(reinstall), for: .valueChanged)

    addField(title: "Field", field: FKKeyboardExampleUI.makeTextField(placeholder: "Show keyboard, then tap empty area"))

    let button = UIButton(type: .system)
    button.setTitle("Still tappable action", for: .normal)
    button.addTarget(self, action: #selector(showAlert), for: .touchUpInside)
    contentStack.addArrangedSubview(button)

    reinstall()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    dismissController?.stop()
  }

  private func makeToggleRow(title: String, control: UISwitch) -> UIStackView {
    let label = UILabel()
    label.text = title
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.numberOfLines = 0
    let row = UIStackView(arrangedSubviews: [label, control])
    row.axis = .horizontal
    row.alignment = .center
    row.spacing = 12
    return row
  }

  @objc
  private func reinstall() {
    dismissController?.stop()
    let controller = FKKeyboardDismissController(
      containerView: view,
      configuration: .init(
        cancelsTouchesInView: cancelsSwitch.isOn,
        ignoresTapsInsideFirstResponder: ignoreSwitch.isOn
      )
    )
    controller.start()
    dismissController = controller
  }

  @objc
  private func showAlert() {
    let alert = UIAlertController(title: "Tapped", message: "Button received the touch.", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }
}
