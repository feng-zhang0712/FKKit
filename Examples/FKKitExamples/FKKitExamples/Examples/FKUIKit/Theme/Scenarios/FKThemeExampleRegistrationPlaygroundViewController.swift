import FKUIKit
import UIKit

/// Live primary color changes with repeated FKThemeRegistry.register calls.
final class FKThemeExampleRegistrationPlaygroundViewController: FKThemeExampleBaseViewController {

  private let previewButton = FKButton()
  private let hueSlider = UISlider()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Registration playground"
    restoresThemeOnExit = true

    hueSlider.minimumValue = 0
    hueSlider.maximumValue = 1
    hueSlider.value = 0.48
    hueSlider.addAction(UIAction { [weak self] _ in self?.applyHue() }, for: .valueChanged)

    previewButton.content = .init(kind: .textOnly)
    previewButton.setTitle(.init(text: "Preview button", font: .preferredFont(forTextStyle: .headline), color: .white), for: .normal)
    previewButton.translatesAutoresizingMaskIntoConstraints = false
    previewButton.heightAnchor.constraint(equalToConstant: 44).isActive = true

    stack.addArrangedSubview(
      FKThemeExampleSupport.card(
        title: "Live re-register",
        description: "Adjust hue to rebuild FKTheme and call FKThemeRegistry.register on every change.",
        content: hueSlider
      )
    )
    stack.addArrangedSubview(previewButton)

    applyHue()
  }

  private func applyHue() {
    let color = UIColor(hue: CGFloat(hueSlider.value), saturation: 0.65, brightness: 0.82, alpha: 1)
    let theme = FKThemeExampleSupport.makeBrandTheme(primary: color)
    FKThemeRegistry.register(theme)

    previewButton.setAppearances(theme.makeButtonStateAppearances(for: .primary))
    let titleColor = theme.buttonTitleColor(for: .primary)
    [UIControl.State.normal, .highlighted, .selected].forEach { state in
      previewButton.setTitle(.init(text: "Preview button", font: .preferredFont(forTextStyle: .headline), color: titleColor), for: state)
    }
  }
}
