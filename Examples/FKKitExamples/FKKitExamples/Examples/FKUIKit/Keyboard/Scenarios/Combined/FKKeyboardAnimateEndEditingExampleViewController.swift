import UIKit
import FKUIKit

/// ``FKKeyboard/animate(alongside:animations:)`` and endEditing helpers.
final class FKKeyboardAnimateEndEditingExampleViewController: FKKeyboardExamplePageViewController {
  private let observer = FKKeyboardObserver()
  private let box = UIView()
  private let field = FKKeyboardExampleUI.makeTextField(placeholder: "Focus to animate the box")

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Animate & endEditing"
    addIntro(
      title: "Facade helpers",
      body: "FKKeyboard.animate(alongside:) matches the system keyboard curve. Use endEditing(in:) / endEditing(around:) to dismiss."
    )
    addField(title: "Field", field: field)

    // Demo target for animate(alongside:) — spaced below the field so a small upward lift
    // does not cover the text input.
    box.backgroundColor = .systemBlue
    box.layer.cornerRadius = 8
    box.translatesAutoresizingMaskIntoConstraints = false
    box.heightAnchor.constraint(equalToConstant: 48).isActive = true
    if let fieldRow = contentStack.arrangedSubviews.last {
      contentStack.setCustomSpacing(24, after: fieldRow)
    }
    contentStack.addArrangedSubview(box)

    let dismissIn = UIButton(type: .system)
    dismissIn.setTitle("FKKeyboard.endEditing(in: view)", for: .normal)
    dismissIn.addTarget(self, action: #selector(endInView), for: .touchUpInside)
    contentStack.addArrangedSubview(dismissIn)

    let dismissAround = UIButton(type: .system)
    dismissAround.setTitle("FKKeyboard.endEditing(around: field)", for: .normal)
    dismissAround.addTarget(self, action: #selector(endAroundField), for: .touchUpInside)
    contentStack.addArrangedSubview(dismissAround)

    observer.onChange = { [weak self] info in
      guard let self else { return }
      // Small lift only — enough to show curve sync without covering the field above.
      let lift = info.isVisible ? -min(36, info.overlapHeight(in: self.view) * 0.08) : 0
      FKKeyboard.animate(alongside: info) {
        self.box.transform = CGAffineTransform(translationX: 0, y: lift)
      }
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    observer.start()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    observer.stop()
  }

  @objc private func endInView() {
    FKKeyboard.endEditing(in: view)
  }

  @objc private func endAroundField() {
    FKKeyboard.endEditing(around: field)
  }
}
