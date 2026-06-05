import FKCoreKit
import UIKit

/// Demonstrates FKI18nStaticDictionaryTranslator as an overlay before bundle lookup.
final class FKI18nDictionaryExampleViewController: FKI18nExampleBaseViewController {

  private let statusLabel = UILabel()
  private var overlayActive = false

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Dictionary Backend"

    statusLabel.font = .preferredFont(forTextStyle: .title3)
    statusLabel.numberOfLines = 0
    stackView.insertArrangedSubview(statusLabel, at: 0)

    addInfoLabel("Dictionary keys override bundle strings for the active language. Toggle to compare sources.")
    addLanguagePickerButton()
    addActionButton("Enable Dictionary Overlay") { [weak self] in
      self?.setOverlay(active: true)
    }
    addActionButton("Disable Dictionary Overlay") { [weak self] in
      self?.setOverlay(active: false)
    }
    addActionButton("Clear Log") { [weak self] in
      self?.clearOutput()
    }

    refreshLocalizedContent()
  }

  override func refreshLocalizedContent() {
    updateStatusLabel()
    logCurrentValue()
  }

  private func setOverlay(active: Bool) {
    overlayActive = active
    if active {
      let translator = FKI18nStaticDictionaryTranslator(
        flatDictionary: dictionaryOverlay(),
        fallbackLanguageCode: FKI18nRecommendedLanguages.english
      )
      FKI18nManager.shared.setDictionaryTranslator(translator)
      appendOutput("overlay=enabled")
    } else {
      FKI18nManager.shared.setDictionaryTranslator(nil)
      appendOutput("overlay=disabled")
    }
    refreshLocalizedContent()
  }

  private func dictionaryOverlay() -> [String: [String: String]] {
    [
      FKI18nRecommendedLanguages.english: [
        "i18n.demo.dictionary.sample": "Remote copy (dictionary — EN override)",
      ],
      FKI18nRecommendedLanguages.simplifiedChinese: [
        "i18n.demo.dictionary.sample": "远程文案（字典）",
      ],
      FKI18nRecommendedLanguages.traditionalChinese: [
        "i18n.demo.dictionary.sample": "遠端文案（字典）",
      ],
      FKI18nRecommendedLanguages.japanese: [
        "i18n.demo.dictionary.sample": "リモート文案（辞書）",
      ],
      FKI18nRecommendedLanguages.korean: [
        "i18n.demo.dictionary.sample": "원격 문구（사전）",
      ],
      FKI18nRecommendedLanguages.spanish: [
        "i18n.demo.dictionary.sample": "Copia remota (diccionario)",
      ],
      FKI18nRecommendedLanguages.french: [
        "i18n.demo.dictionary.sample": "Copie distante (dictionnaire)",
      ],
      FKI18nRecommendedLanguages.german: [
        "i18n.demo.dictionary.sample": "Remote-Text (Wörterbuch)",
      ],
      FKI18nRecommendedLanguages.portugueseBrazil: [
        "i18n.demo.dictionary.sample": "Cópia remota (dicionário)",
      ],
      FKI18nRecommendedLanguages.arabic: [
        "i18n.demo.dictionary.sample": "نسخة عن بُعد (قاموس)",
      ],
      FKI18nRecommendedLanguages.russian: [
        "i18n.demo.dictionary.sample": "Удалённый текст (словарь)",
      ],
    ]
  }

  private func updateStatusLabel() {
    statusLabel.text = overlayActive
      ? FKI18nExampleSupport.localized("i18n.demo.dictionary.active")
      : FKI18nExampleSupport.localized("i18n.demo.dictionary.inactive")
  }

  private func logCurrentValue() {
    let key = "i18n.demo.dictionary.sample"
    let value = FKI18nManager.shared.localized(key, table: FKI18nExampleSupport.demoTable)
    appendOutput("language=\(FKI18nManager.shared.currentLanguageCode)")
    appendOutput("key=\(key)")
    appendOutput("value=\(value)")
    appendOutput("source=\(overlayActive ? "dictionary" : "bundle")")
  }
}
