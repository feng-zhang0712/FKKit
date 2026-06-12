import FKUIKit
import UIKit

/// Demonstrates themeDidChangeNotification and FKThemeAware.
final class FKThemeExampleRegistryNotificationViewController: FKThemeExampleBaseViewController {

  private let banner = FKThemeAwareBannerView()
  private let counterLabel = UILabel()
  private var notificationCount = 0
  private var themeObserver: NSObjectProtocol?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Registry & FKThemeAware"
    restoresThemeOnExit = true

    counterLabel.font = .preferredFont(forTextStyle: .footnote)
    counterLabel.textColor = .secondaryLabel
    counterLabel.text = "Notifications received: 0"

    themeObserver = NotificationCenter.default.addObserver(
      forName: FKThemeRegistry.themeDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.themeChanged()
    }

    stack.addArrangedSubview(banner)
    stack.addArrangedSubview(counterLabel)

    var tealConfig = UIButton.Configuration.filled()
    tealConfig.title = "Register teal brand"
    let tealButton = UIButton(configuration: tealConfig)
    tealButton.addAction(UIAction { _ in
      FKThemeRegistry.register(FKThemeExampleSupport.makeBrandTheme(primary: .systemTeal))
    }, for: .touchUpInside)

    var purpleConfig = UIButton.Configuration.filled()
    purpleConfig.baseBackgroundColor = .systemPurple
    purpleConfig.title = "Register purple brand"
    let purpleButton = UIButton(configuration: purpleConfig)
    purpleButton.addAction(UIAction { _ in
      FKThemeRegistry.register(FKThemeExampleSupport.makeBrandTheme(primary: .systemPurple))
    }, for: .touchUpInside)

    let buttons = UIStackView(arrangedSubviews: [tealButton, purpleButton])
    buttons.axis = .vertical
    buttons.spacing = 10

    stack.addArrangedSubview(
      FKThemeExampleSupport.card(
        title: "Live refresh",
        description: "FKThemeAwareBannerView conforms to FKThemeAware and listens for themeDidChangeNotification.",
        content: buttons
      )
    )
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if let themeObserver {
      NotificationCenter.default.removeObserver(themeObserver)
      self.themeObserver = nil
    }
  }

  private func themeChanged() {
    notificationCount += 1
    counterLabel.text = "Notifications received: \(notificationCount)"
  }
}
