import FKUIKit
import UIKit

/// Toggles FKThemeApplicationOptions when registering themes.
final class FKThemeExampleApplicationOptionsViewController: FKThemeExampleBaseViewController {

  private let postsSwitch = UISwitch()
  private let refreshSwitch = UISwitch()
  private let componentsSwitch = UISwitch()
  private let logLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Application options"
    restoresThemeOnExit = true

    postsSwitch.isOn = true
    refreshSwitch.isOn = true
    componentsSwitch.isOn = true

    logLabel.numberOfLines = 0
    logLabel.font = .preferredFont(forTextStyle: .footnote)
    logLabel.textColor = .secondaryLabel

    stack.addArrangedSubview(optionRow(title: "postsNotification", toggle: postsSwitch))
    stack.addArrangedSubview(optionRow(title: "refreshesVisibleWindows", toggle: refreshSwitch))
    stack.addArrangedSubview(optionRow(title: "appliesComponentDefaults", toggle: componentsSwitch))
    stack.addArrangedSubview(logLabel)

    var applyConfig = UIButton.Configuration.filled()
    applyConfig.title = "Register with selected options"
    let applyButton = UIButton(configuration: applyConfig)
    applyButton.addAction(UIAction { [weak self] _ in self?.registerTheme() }, for: .touchUpInside)
    stack.addArrangedSubview(applyButton)
  }

  private func optionRow(title: String, toggle: UISwitch) -> UIStackView {
    let label = UILabel()
    label.text = title
    label.font = .preferredFont(forTextStyle: .body)
    let row = UIStackView(arrangedSubviews: [label, toggle])
    row.axis = .horizontal
    row.alignment = .center
    return row
  }

  private func registerTheme() {
    let options = FKThemeApplicationOptions(
      postsNotification: postsSwitch.isOn,
      refreshesVisibleWindows: refreshSwitch.isOn,
      appliesComponentDefaults: componentsSwitch.isOn
    )
    FKThemeRegistry.register(FKThemeExampleSupport.makeBrandTheme(), options: options)
    logLabel.text = """
    Registered with posts=\(options.postsNotification), refresh=\(options.refreshesVisibleWindows), components=\(options.appliesComponentDefaults)
    Button appearances: \(FKButtonGlobalStyle.defaultAppearances == nil ? "nil" : "set")
    """
  }
}
