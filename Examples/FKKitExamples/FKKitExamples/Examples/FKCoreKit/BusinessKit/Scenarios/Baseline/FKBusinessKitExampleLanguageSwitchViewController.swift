import UIKit
import FKCoreKit

/// B4 — in-app language switch with relative time formatter refresh.
final class FKBusinessKitExampleLanguageSwitchViewController: FKBusinessKitExampleBaseViewController {
  private var languageToken: FKBusinessObservationToken?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "LanguageSwitch"
    languageToken = kit.i18n.observeLanguageChange { [weak self] code in
      Task { @MainActor in
        self?.appendLog("Language observer: \(code)")
        self?.refreshRelativeSample()
      }
    }
    addInfoLabel("Toggle en ↔ zh-Hans and observe relative time output.")
    addActionButton("Toggle language") { [weak self] in
      guard let self else { return }
      let next = self.kit.i18n.currentLanguageCode.lowercased().hasPrefix("zh") ? "en" : "zh-Hans"
      self.kit.i18n.setLanguageCode(next)
      self.appendLog("setLanguageCode(\(next))")
    }
    refreshRelativeSample()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if isMovingFromParent {
      languageToken?.invalidate()
      languageToken = nil
    }
  }

  private func refreshRelativeSample() {
    let earlier = Date().addingTimeInterval(-135)
    let text = kit.utils.time.relativeDescription(from: earlier, now: Date())
    appendLog("Relative: \(text) [\(kit.i18n.currentLanguageCode)]")
  }
}
