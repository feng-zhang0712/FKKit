import FKCoreKit
import UIKit

/// Demonstrates `FKLocalizing` and `FKTranslating`.
@MainActor
final class FKPluggableLocalizationExampleViewController: FKPluggableExampleBaseViewController {

  private let localizer = DemoLocalizer()
  private let translator = DemoTranslator()
  private var languageToken: FKPluggableObservationToken?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Pluggable · Localization"

    languageToken = localizer.observeLanguageChange { [weak self] code in
      Task { @MainActor in self?.appendOutput("Language observer: \(code)") }
    }

    addActionButton("1) localized(_:table:) — English") { [weak self] in
      self?.localizer.setLanguageCode("en")
      self?.appendLocalizedStrings()
    }
    addActionButton("2) localized(_:table:) — Japanese") { [weak self] in
      self?.localizer.setLanguageCode("ja")
      self?.appendLocalizedStrings()
    }
    addActionButton("3) FKTranslating — welcomeTitle") { [weak self] in
      let en = self?.translator.translate(.welcomeTitle, locale: "en", variables: [:]) ?? ""
      let ja = self?.translator.translate(.welcomeTitle, locale: "ja", variables: [:]) ?? ""
      self?.appendOutput("welcomeTitle en='\(en)' ja='\(ja)'")
    }
    addActionButton("4) FKTranslating — itemCount with variables") { [weak self] in
      let vars = ["count": "3"]
      let en = self?.translator.translate(.itemCount, locale: "en", variables: vars) ?? ""
      let ja = self?.translator.translate(.itemCount, locale: "ja", variables: vars) ?? ""
      self?.appendOutput("itemCount en='\(en)' ja='\(ja)'")
    }
    addActionButton("5) currentLanguageCode") { [weak self] in
      self?.appendOutput("currentLanguageCode = \(self?.localizer.currentLanguageCode ?? "?")")
    }
    addActionButton("Clear log") { [weak self] in self?.clearOutput() }
  }

  private func appendLocalizedStrings() {
    appendOutput("greeting = \(localizer.localized("greeting", table: nil))")
    appendOutput("farewell = \(localizer.localized("farewell", table: nil))")
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    if isMovingFromParent || isBeingDismissed {
      languageToken?.cancel()
      languageToken = nil
    }
  }
}
