import FKUIKit
import UIKit

final class FKQRCodeScannerExampleScanModesViewController: FKQRCodeScannerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Scan Modes"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKQRCodeExampleUI.button("scanMode = .once") { [weak self] in
      var config = FKQRCodeScannerConfiguration.default
      config.scanMode = .once
      self?.presentScanner(label: "mode.once", configuration: config)
    })
    body.addArrangedSubview(FKQRCodeExampleUI.button("scanMode = .continuous") { [weak self] in
      var config = FKQRCodeScannerConfiguration.default
      config.scanMode = .continuous
      config.cooldownInterval = 1.5
      self?.presentScanner(label: "mode.continuous", configuration: config)
    })

    contentStack.addArrangedSubview(
      FKQRCodeExampleUI.section(
        title: "FKQRCodeScanMode",
        description: ".once pauses capture after the first successful read. .continuous keeps the session running (use cooldown to limit duplicate callbacks).",
        body: body
      )
    )
    contentStack.addArrangedSubview(
      FKQRCodeExampleUI.caption("In .once mode the preview freezes after scan; dismiss manually with the close button.")
    )
    addClearLogButton()
  }
}
