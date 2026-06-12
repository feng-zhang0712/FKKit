import FKUIKit
import UIKit

/// Demonstrates makeToastConfiguration mapped from theme tokens.
final class FKThemeExampleToastIntegrationViewController: FKThemeExampleBaseViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Toast defaults"
    restoresThemeOnExit = true

    let brand = FKThemeExampleSupport.makeBrandTheme()
    FKThemeRegistry.register(brand)

    let config = brand.makeToastConfiguration()
    let summary = UILabel()
    summary.numberOfLines = 0
    summary.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    summary.text = """
    textColor: \(config.textColor.description)
    backgroundColor: \(config.backgroundColor?.description ?? "nil")
    cornerRadius: \(config.cornerRadius.map { String(format: "%.1f", $0) } ?? "nil")
    shadowRadius: \(config.shadowRadius)
    """

    stack.addArrangedSubview(
      FKThemeExampleSupport.card(
        title: "makeToastConfiguration()",
        description: "Maps surfaceElevated, onSurface, typography, metrics, and elevationMedium shadow.",
        content: summary
      )
    )

    var buttonConfig = UIButton.Configuration.filled()
    buttonConfig.title = "Show toast with themed defaults"
    let button = UIButton(configuration: buttonConfig)
    button.addAction(UIAction { _ in
      FKToast.show("Shipment confirmed", style: .success)
    }, for: .touchUpInside)
    stack.addArrangedSubview(button)
  }
}
