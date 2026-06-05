import FKCoreKit
import UIKit

/// Demonstrates observeLanguageChange tokens and NotificationCenter broadcasts.
final class FKI18nObserverExampleViewController: FKI18nExampleBaseViewController {

  private var observationToken: FKI18nObservationToken?
  private var notificationToken: NSObjectProtocol?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Observers"

    addInfoLabel("Registers FKI18nObservationToken and listens for FKI18nManager.languageDidChangeNotification.")
    addLanguagePickerButton()
    addActionButton("Reset to English") {
      FKI18nManager.shared.setLanguageCode(FKI18nRecommendedLanguages.english)
    }
    addActionButton("Clear Log") { [weak self] in
      self?.clearOutput()
    }

    observationToken = FKI18nManager.shared.observeLanguageChange { [weak self] language in
      Task { @MainActor in
        self?.appendOutput("token → \(language.code)")
      }
    }

    notificationToken = NotificationCenter.default.addObserver(
      forName: FKI18nManager.languageDidChangeNotification,
      object: FKI18nManager.shared,
      queue: .main
    ) { [weak self] notification in
      let from = notification.userInfo?[FKI18nNotificationKey.previousLanguageCode] as? String ?? "?"
      let to = notification.userInfo?[FKI18nNotificationKey.languageCode] as? String ?? "?"
      Task { @MainActor in
        self?.appendOutput(
          FKI18nExampleSupport.localized(
            "i18n.demo.observer.changed",
            variables: ["from": from, "to": to]
          )
        )
      }
    }

    appendOutput("current=\(FKI18nManager.shared.currentLanguageCode)")
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if isMovingFromParent || isBeingDismissed, let notificationToken {
      NotificationCenter.default.removeObserver(notificationToken)
      self.notificationToken = nil
    }
  }
}
