import FKUIKit
import UIKit

/// Registers a brand theme and demonstrates Button / Toast integration.
final class FKThemeExampleCustomBrandViewController: FKThemeExampleBaseViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom brand"
    restoresThemeOnExit = true

    let brand = FKThemeExampleSupport.makeBrandTheme()
    FKThemeRegistry.register(brand)

    stack.addArrangedSubview(
      FKThemeExampleSupport.bodyLabel("Registered theme id: \(brand.id). New buttons inherit GlobalStyle.defaultAppearances.")
    )

    let themedButton = FKButton()
    themedButton.content = .init(kind: .textOnly)
    themedButton.setTitle(.init(text: "Themed primary button", font: .preferredFont(forTextStyle: .headline), color: .white), for: .normal)
    themedButton.translatesAutoresizingMaskIntoConstraints = false
    themedButton.heightAnchor.constraint(equalToConstant: 44).isActive = true

    stack.addArrangedSubview(
      FKThemeExampleSupport.card(
        title: "FKButtonGlobalStyle",
        description: "Created after register — filled primary background and onPrimary title from the theme.",
        content: themedButton
      )
    )

    var toastButtonConfig = UIButton.Configuration.filled()
    toastButtonConfig.title = "Show themed toast"
    let toastButton = UIButton(configuration: toastButtonConfig)
    toastButton.addAction(UIAction { _ in
      FKToast.show("Themed toast from FKToast.defaultConfiguration", style: .normal)
    }, for: .touchUpInside)

    stack.addArrangedSubview(
      FKThemeExampleSupport.card(
        title: "FKToast.defaultConfiguration",
        description: "Toast uses surfaceElevated background and onSurface text from makeToastConfiguration().",
        content: toastButton
      )
    )
  }
}
