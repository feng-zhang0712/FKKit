import FKCoreKit
import FKUIKit
import UIKit

final class FKTextFieldExampleI18nViewController: FKTextFieldExamplePageViewController {
  private enum LocaleMode {
    case english
    case chinese
  }

  private var localeMode: LocaleMode = .english
  private let localizedField = FKTextField.makeEmail()
  private var languageObservation: FKI18nObservationToken?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "I18N & Accessibility"
    build()
    languageObservation = FKI18nManager.shared.observeLanguageChange { [weak self] _ in
      Task { @MainActor in self?.applyLocale() }
    }
    applyLocale()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if isMovingFromParent || isBeingDismissed {
      FKI18nExampleSupport.syncWithDeviceLanguage()
    }
  }

  private func build() {
    addSection(title: "Locale Switch (EN / ZH)", note: "Uses FKI18nManager + FKUIKit bundled strings for accessories and announcements.")
    let localeControl = UISegmentedControl(items: ["English", "中文"])
    localeControl.selectedSegmentIndex = FKI18nManager.shared.currentLanguageCode == FKI18nRecommendedLanguages.simplifiedChinese ? 1 : 0
    localeMode = localeControl.selectedSegmentIndex == 0 ? .english : .chinese
    localeControl.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISegmentedControl else { return }
      self.localeMode = (control.selectedSegmentIndex == 0) ? .english : .chinese
      self.applyLocale()
    }, for: .valueChanged)
    stack.addArrangedSubview(localeControl)

    var config = FKTextFieldConfiguration(inputRule: FKTextFieldInputRule(formatType: .email))
    config.inlineMessage.showsErrorMessage = true
    config.messages.helper = "Use a valid email address."
    localizedField.configure(config)
    addField(title: "Localized field", field: localizedField, ruleHint: "Placeholder and accessories follow FKI18nManager.")

    addSection(title: "RTL Preview", note: "Forces right-to-left layout direction to verify prefix/suffix and text alignment behavior.")
    let rtl = FKTextField.makePhone()
    rtl.semanticContentAttribute = .forceRightToLeft
    rtl.textAlignment = .right
    addField(title: "RTL forced phone field", field: rtl, ruleHint: "Allowed: digits only. Layout is forced RTL.")

    addSection(title: "Dynamic Type", note: "Uses preferred text styles and supports larger content sizes without truncation.")
    var dynamicConfig = FKTextFieldConfiguration(inputRule: FKTextFieldInputRule(formatType: .alphaNumeric))
    dynamicConfig.style.font = .preferredFont(forTextStyle: .title3)
    dynamicConfig.style.placeholderFont = .preferredFont(forTextStyle: .title3)
    dynamicConfig.floatingTitle = "Dynamic Type Title"
    let dynamicField = FKTextField(configuration: dynamicConfig)
    addField(title: "Large text style field", field: dynamicField, ruleHint: "Allowed: A-Z, a-z, 0-9. Dynamic Type friendly typography.")

    addSection(title: "VoiceOver Key Behavior", note: "Error and success messages are announced. Toggle VoiceOver to verify spoken feedback after validation changes.")
    let voButton = UIButton(type: .system)
    voButton.setTitle("Trigger VoiceOver announcement state", for: .normal)
    voButton.addAction(UIAction { [weak self] _ in
      self?.localizedField.setError(message: FKUIKitI18n.string("fkuikit.textfield.validation.email"))
    }, for: .touchUpInside)
    stack.addArrangedSubview(voButton)
  }

  private func applyLocale() {
    let code = localeMode == .english
      ? FKI18nRecommendedLanguages.english
      : FKI18nRecommendedLanguages.simplifiedChinese
    FKI18nManager.shared.setLanguageCode(code)

    var config = localizedField.configuration
    config.placeholder = FKUIKitI18n.string("fkuikit.textfield.placeholder.email")
    config.messages.helper = localeMode == .english
      ? "Use a valid email address."
      : "请输入有效邮箱地址。"
    localizedField.configure(config)
    localizedField.setNeedsLayout()
  }
}
