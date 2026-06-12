import FKUIKit
import UIKit

final class FKQRCodeScannerExampleDebounceViewController: FKQRCodeScannerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Debounce"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKQRCodeExampleUI.button("cooldownInterval = 3s (default debounce)") { [weak self] in
      var config = FKQRCodeScannerConfiguration.default
      config.scanMode = .continuous
      config.cooldownInterval = 3.0
      config.allowsMultipleCallbacks = false
      self?.presentScanner(label: "debounce.3s", configuration: config)
    })
    body.addArrangedSubview(FKQRCodeExampleUI.button("allowsMultipleCallbacks = true") { [weak self] in
      var config = FKQRCodeScannerConfiguration.default
      config.scanMode = .continuous
      config.cooldownInterval = 2.0
      config.allowsMultipleCallbacks = true
      self?.presentScanner(label: "debounce.allowAll", configuration: config)
    })

    contentStack.addArrangedSubview(
      FKQRCodeExampleUI.section(
        title: "Duplicate suppression",
        description: "Hold the same QR in frame — with default settings you should see one callback per cooldown window. Timestamps in the log help verify FKDebouncer behavior.",
        body: body
      )
    )
    addClearLogButton()
  }
}
