import FKUIKit
import UIKit

/// Registers a brand theme, then restores FKTheme.default factory component settings.
final class FKThemeExampleRestoreDefaultsViewController: FKThemeExampleBaseViewController {

  private let statusLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Restore defaults"

    statusLabel.numberOfLines = 0
    statusLabel.font = .preferredFont(forTextStyle: .body)

    stack.addArrangedSubview(
      FKThemeExampleSupport.card(
        title: "Workflow",
        description: "1) Register brand theme. 2) Tap restore to call FKThemeComponentIntegration.restoreFactoryComponentDefaults() via FKTheme.default registration.",
        content: statusLabel
      )
    )

    var registerConfig = UIButton.Configuration.filled()
    registerConfig.title = "Register brand theme"
    let registerButton = UIButton(configuration: registerConfig)
    registerButton.addAction(UIAction { [weak self] _ in
      FKThemeRegistry.register(FKThemeExampleSupport.makeBrandTheme())
      self?.refreshStatus()
    }, for: .touchUpInside)

    var restoreConfig = UIButton.Configuration.gray()
    restoreConfig.title = "Restore FKTheme.default"
    let restoreButton = UIButton(configuration: restoreConfig)
    restoreButton.addAction(UIAction { [weak self] _ in
      FKThemeRegistry.register(FKTheme.default)
      self?.refreshStatus()
    }, for: .touchUpInside)

    let actions = UIStackView(arrangedSubviews: [registerButton, restoreButton])
    actions.axis = .vertical
    actions.spacing = 10
    stack.addArrangedSubview(actions)

    refreshStatus()
  }

  private func refreshStatus() {
    let appearances = FKButtonGlobalStyle.defaultAppearances == nil ? "nil" : "set"
    statusLabel.text = """
    Theme id: \(FKThemeRegistry.current.id)
    Button GlobalStyle.defaultAppearances: \(appearances)
    Toast textColor: \(FKToast.defaultConfiguration.textColor.description)
    """
  }
}
