import FKUIKit
import UIKit

/// Shows factory component defaults when the built-in theme has not been registered.
final class FKThemeExampleDefaultBaselineViewController: FKThemeExampleBaseViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Default baseline"

    let info = FKThemeExampleSupport.bodyLabel(
      "Current theme id: \(FKThemeRegistry.current.id). GlobalStyle.defaultAppearances is \(FKButtonGlobalStyle.defaultAppearances == nil ? "nil" : "set")."
    )
    stack.addArrangedSubview(info)

    let plainButton = FKButton()
    plainButton.content = .init(kind: .textOnly)
    plainButton.setTitle(.init(text: "New FKButton (factory)", font: .preferredFont(forTextStyle: .headline), color: .label), for: .normal)
    plainButton.translatesAutoresizingMaskIntoConstraints = false
    plainButton.heightAnchor.constraint(equalToConstant: 44).isActive = true

    stack.addArrangedSubview(
      FKThemeExampleSupport.card(
        title: "Unregistered global style",
        description: "Buttons created here use per-instance styling unless FKThemeRegistry.register applies component defaults.",
        content: plainButton
      )
    )

    stack.addArrangedSubview(
      FKThemeExampleSupport.card(
        title: "Toast factory defaults",
        description: "FKToast.defaultConfiguration keeps white text unless a custom theme is registered.",
        content: makeToastButton()
      )
    )
  }

  private func makeToastButton() -> UIButton {
    var config = UIButton.Configuration.filled()
    config.title = "Show factory toast"
    let button = UIButton(configuration: config)
    button.addAction(UIAction { _ in
      FKToast.show("Factory toast styling", style: .normal)
    }, for: .touchUpInside)
    return button
  }
}
