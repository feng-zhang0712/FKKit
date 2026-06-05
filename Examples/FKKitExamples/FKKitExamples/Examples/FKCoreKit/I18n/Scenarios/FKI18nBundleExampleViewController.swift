import FKCoreKit
import UIKit

/// Demonstrates bundle-based string resolution from demo `.lproj` folders.
final class FKI18nBundleExampleViewController: FKI18nExampleBaseViewController {

  private let sampleLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Bundle Strings"

    sampleLabel.font = .preferredFont(forTextStyle: .title3)
    sampleLabel.numberOfLines = 0
    stackView.insertArrangedSubview(sampleLabel, at: 0)

    addInfoLabel(
      "Strings load from Support/Resources/Localization/<code>.lproj/FKI18nDemo.strings via FKI18nConfiguration.bundle."
    )
    addLanguagePickerButton()
    addActionButton("Resolve Sample Key") { [weak self] in
      self?.logBundleLookup()
    }
    addActionButton("Clear Log") { [weak self] in
      self?.clearOutput()
    }

    refreshLocalizedContent()
    logBundleLookup()
  }

  override func refreshLocalizedContent() {
    sampleLabel.text = FKI18nExampleSupport.localized("i18n.demo.bundle.sample")
  }

  private func logBundleLookup() {
    let i18n = FKI18nManager.shared
    let key = "i18n.demo.bundle.sample"
    let value = i18n.localized(key, table: FKI18nExampleSupport.demoTable)
    appendOutput("language=\(i18n.currentLanguageCode)")
    appendOutput("key=\(key)")
    appendOutput("value=\(value)")
    appendOutput(FKI18nExampleSupport.localized("i18n.demo.bundle.resolved"))
  }
}
